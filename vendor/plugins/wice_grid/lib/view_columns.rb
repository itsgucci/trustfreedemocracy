module Wice

  class ViewColumn < Struct.new(:attribute_name, :column_name, :td_html_attrs, :cell_rendering_block) #:nodoc:
    include ActionView::Helpers::FormTagHelper
    include ActionView::Helpers::TagHelper      
    include ActionView::Helpers::JavaScriptHelper
    attr_accessor :grid, :css_class, :table_name, :main_table, :model_class, :no_filter, :custom_filter, :in_html, :in_csv
    cattr_accessor :handled_type
    @@handled_type = Hash.new
    
    def css_class #:nodoc:
      @css_class || ''
    end
        
    def enter_key_handler #:nodoc:
      @enter_key_handler ||= "if (event.keyCode == 13) {#{grid.name}.process()}"
    end
      
    def yield_processing_function #:nodoc:
      nil
    end      
  
    def yield_javascript #:nodoc:
      processing_function = yield_processing_function
      if processing_function
        "#{@grid.name}.register( #{processing_function});"
      else
        ''
      end
    end
  
    def render_filter #:nodoc:
      params = @grid.filter_params(self)
      return render_filter_internal(params)
    end
  
    def render_filter_internal(params) #:nodoc:
      '<!-- implement me! -->'
    end


    def form_parameter_name_id_and_query(v) #:nodoc:
      query = form_parameter_template(v)
      query_without_equals_sign = query.sub(/=$/,'')
      parameter_name = CGI.unescape(query_without_equals_sign)
      dom_id = id_out_of_name(parameter_name)
      return query, query_without_equals_sign, parameter_name, dom_id.tr('.','_')
    end
  


    def fully_qualified_attribute_name #:nodoc:
      self.main_table ? attribute_name : table_name + '.' + attribute_name
    end
  
    def filter_shown? #:nodoc:
      self.attribute_name and not self.no_filter
    end
  
    protected

    def form_parameter_template(v) #:nodoc:
      {@grid.name => {:f => {self.fully_qualified_attribute_name => v}}}.to_query
    end

    def form_parameter_name(v) #:nodoc:
      form_parameter_template_hash(v).to_query
    end

    def name_out_of_template(s) #:nodoc:
      CGI.unescape(s).sub(/=$/,'')
    end
  
    def id_out_of_name(s) #:nodoc:
      s.gsub(/[\[\]]+/,'_').sub(/_+$/, '')
    end
  
  end 

  class ViewColumnInteger < ViewColumn #:nodoc:
    @@handled_type[:integer] = self
  
    def render_filter_internal(params) #:nodoc:
    
      @query, _, parameter_name, @dom_id = form_parameter_name_id_and_query(:fr => '')
      @query2, _, parameter_name2, @dom_id2 = form_parameter_name_id_and_query(:to => '')
    
    
      text_field_tag(parameter_name,  params[:fr], :size => 3, :onkeydown=>enter_key_handler, :id => @dom_id) +
      text_field_tag(parameter_name2, params[:to], :size => 3, :onkeydown=>enter_key_handler, :id => @dom_id2)
    end
  
    def yield_processing_function #:nodoc:
      "function(){
        return #{@grid.name}.read_values_and_form_query_string(['#{@query}', '#{@query2}'], ['#{@dom_id}', '#{@dom_id2}']);      
      }"
    end
  end
  
  class ViewColumnFloat < ViewColumnInteger #:nodoc:
    @@handled_type[:decimal] = self    
  end  

  class ViewColumnCustomDropdown < ViewColumn #:nodoc:
    include ActionView::Helpers::FormOptionsHelper
    
    attr_accessor :filter_all_label    
    attr_accessor :custom_filter
    
    def render_filter_internal(params) #:nodoc:
      @query, @query_without_equals_sign, @parameter_name, @dom_id = form_parameter_name_id_and_query('')
      @query_without_equals_sign += '%5B%5D='
      
      @custom_filter = @custom_filter.call if @custom_filter.kind_of? Proc
      
      if @custom_filter.kind_of? Array
        @custom_filter = [[@filter_all_label, nil]] + @custom_filter.map{|fo| fo = fo.to_s.strip; [fo, fo]}
      end
      
      select_options = {:name => @parameter_name, :id => @dom_id}

      if @turn_off_select_toggling
        select_toggle = ''        
      else
        select_options[:class] = 'custom_dropdown'
        select_options[:multiple] = params.size > 1
        select_toggle = content_tag(:a, 
          content_tag(:img, '', :alt => 'Expand/Collapse', :src => Defaults::TOGGLE_MULTI_SELECT_ICON),
          :href => "javascript: toggle_multi_select('#{@dom_id}', this, 'Expand', 'Collapse');",  
          :class => 'toggle_multi_select_icon', :title => 'Expand')
      end
      
      '<div class="custom_dropdown_container">' +
      content_tag(:select, options_for_select(custom_filter, params), select_options) + 
      select_toggle + '</div>'
    end
  
    def yield_processing_function #:nodoc:
      "function(){
        return #{@grid.name}.read_values_and_form_query_string(['#{@query_without_equals_sign}'], ['#{@dom_id}']);
      }"
    end
  end


  class ViewColumnBoolean < ViewColumnCustomDropdown #:nodoc:
    @@handled_type[:boolean] = self
    include ActionView::Helpers::FormOptionsHelper
   
    attr_accessor :boolean_filter_true_label, :boolean_filter_false_label
   
    def render_filter_internal(params) #:nodoc:
      @custom_filter = {@filter_all_label => nil,
                        @boolean_filter_true_label  => 't', 
                        @boolean_filter_false_label => 'f' }
      @turn_off_select_toggling = true
      super(params)
    end
  end
  

  class ViewColumnDatetime < ViewColumn #:nodoc:
    @@handled_type[:datetime] = self
    include ActionView::Helpers::DateHelper

    # name_and_id_from_options in Rails Date helper does not substitute '.' with '_'
    # like all other simpler form helpers do. Thus, overriding it here.
    def name_and_id_from_options(options, type)  #:nodoc:
      options[:name] = (options[:prefix] || DEFAULT_PREFIX) + (options[:discard_type] ? '' : "[#{type}]")
      options[:id] = options[:name].gsub(/([\[\(])|(\]\[)/, '_').gsub(/[\]\)]/, '').gsub(/\./, '_').gsub(/_+/, '_')
    end
    

    @@datetime_chunk_names = %w(year month day hour minute)

    def prepare #:nodoc:
    
      x = lambda{|sym|
        @@datetime_chunk_names.collect{|datetime_chunk_name| 
          triple = form_parameter_name_id_and_query(sym => {datetime_chunk_name => ''})
          [triple[0], triple[3]]
        }
      }
    
      @queris_ids = x.call(:fr) + x.call(:to)

      _, _, @name1, _ = form_parameter_name_id_and_query({:fr => ''})
      _, _, @name2, _ = form_parameter_name_id_and_query({:to => ''})
    
    end

    def render_filter_internal(params) #:nodoc:
      prepare
      select_datetime(params[:fr], {:include_blank => true, :prefix => @name1}) + '<br/>' +
      select_datetime(params[:to], {:include_blank => true, :prefix => @name2})
    end

    def yield_processing_function #:nodoc:
      "function(){
        return #{@grid.name}.read_values_and_form_query_string([" + 
          @queris_ids.collect{|tuple| "'" + tuple[0] + "'"}.join(', ') +
          "], [" + 
          @queris_ids.collect{|tuple| "'" + tuple[1] + "'"}.join(', ') +
          "]);      
      }"
    end

  end

  class ViewColumnDate < ViewColumnDatetime #:nodoc:
    @@handled_type[:date] = self
    # include ActionView::Helpers::DateHelper

    @@datetime_chunk_names = %w(year month day)
  
    def render_filter_internal(params) #:nodoc:
      prepare
      select_date(params[:fr], {:include_blank => true, :prefix => @name1}) + '<br/>' +
      select_date(params[:to], {:include_blank => true, :prefix => @name2})
    end
  
  end



  class ViewColumnString < ViewColumn #:nodoc:
    @@handled_type[:string] = self
    @@handled_type[:text] = self
      
    def render_filter_internal(params) #:nodoc:
      @query, _, parameter_name, @dom_id = form_parameter_name_id_and_query('')        
      text_field_tag(parameter_name, params, :size => 8, :onkeydown=>enter_key_handler, :id => @dom_id)
    end

    def yield_processing_function #:nodoc:
      "function(){
        return #{@grid.name}.read_values_and_form_query_string(['#{@query}'], ['#{@dom_id}']);
      }"
    end      
  end

end