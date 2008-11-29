require 'will_paginate'
module Wice
  class GridRenderer

    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::CaptureHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::AssetTagHelper
    include ActionView::Helpers::JavaScriptHelper
    include WillPaginate::ViewHelpers

    
    attr_reader :page_parameter_name
    attr_reader :grid
  
    @@order_parameter_name = "order"
    @@order_direction_parameter_name = "order_direction"
    @@page_parameter_name = "page"
  
    def initialize(grid)  #:nodoc:
      @grid = grid
      @columns = []
    end
  
    def number_of_columns(filter = nil)  #:nodoc:
      filter_columns(filter).size
    end
  
    def each_column_label(filter = nil)  #:nodoc:
      filter_columns(filter).each{|col| yield col.column_name}
    end
    
    def column_labels(filter = nil)  #:nodoc:
      filter_columns(filter).collect(&:column_name)
    end

    def each_column(filter = nil)  #:nodoc:
      filter_columns(filter).each{|col| yield col}
    end
  
    alias_method :each, :each_column
    include Enumerable

    def csv_export_icon #:nodoc:
      if @grid.export_to_csv_enabled
        link_to_function(
          image_tag(Defaults::CSV_EXPORT_ICON, 
            :title => Defaults::CSV_EXPORT_TOOLTIP, 
            :alt => Defaults::CSV_EXPORT_TOOLTIP), "#{grid.name}.export_to_csv()")
      else
        nil
      end
    end

    def pagination_panel(no_rightmost_column)  #:nodoc:
      panel = yield
      number_of_columns = self.number_of_columns(:in_html)
      number_of_columns -= 1 if no_rightmost_column
      csv_icon = csv_export_icon
      if panel.nil? 
        if csv_export_icon.nil?
          ''
        else
          "<tr><td colspan=\"#{number_of_columns}\"></td><td>#{csv_export_icon}</td></tr>"
        end
      else
        if csv_export_icon.nil?
          "<tr><td colspan=\"#{number_of_columns + 1}\">#{panel}</td></tr>"
        else
          "<tr><td colspan=\"#{number_of_columns}\">#{panel}</td><td>#{csv_export_icon}</td></tr>"          
        end        
      end
    end

    # Defines everything related to a column in a grid - column name, filtering, rendering cells, etc.
    #
    # +column+ is only used inside the block of the +grid+ method. See documentation for the +grid+ method for more details.
    # 
    # The only parameter is a hash of options. None of them is optional. If no options are supplied, the result will be a column with no 
    # name, no filtering and no sorting.
    #
    # * <tt>:column_name</tt> - Name of the column.
    # * <tt>:td_html_attrs</tt> - a hash of HTML attributes to be included into the <tt>td</tt> tag.
    # * <tt>:attribute_name</tt> - name of a database column (which normally correspond to a model attribute with the same name). By default the
    #   field is assumed to belong to the default table (see documentation for the +initialize_grid+ method). Parameter <tt>:model_class</tt>
    #   allows to specify another table. Presence of this parameter
    #   * adds sorting capabilities by this field
    #   * automatically creates a filter based on the type of the field unless parameter <tt>:no_filter</tt> is set to true. 
    #     The following filters exist for the following types:
    #     * <tt>string</tt> - a text field
    #     * <tt>integer</tt> and <tt>float</tt>  - two text fields to specify the range. Both limits or only one can be specified
    #     * <tt>boolean</tt> - a dropdown list with 'yes', 'no', or '-'. These labels can be changed in <tt>lib/wice_grid_config.rb</tt>
    #     * <tt>date</tt> - two sets of standard date dropdown lists so specify the time range.
    #     * <tt>datetime</tt> - two sets of standard datetime dropdown lists so specify the time range. At this moment this filter 
    #       is far from being user-friendly due to the number of dropdown lists.
    # * <tt>:no_filter</tt> - Turns off filters even if <tt>:attribute_name</tt> is specified. This is needed if sorting is required while
    #   filters are not.
    # * <tt>:model_class</tt> - Name of the model class to which <tt>:attribute_name</tt> belongs to if this is not the main table.
    # * <tt>:custom_filter</tt> - Allows to construct a custom dropdown filter. Depending on the value of <tt>:custom_filter</tt> different
    #   modes are available:
    #   * array of strings - this is a direct manual definition of possible values of the dropdown. The filter for boolean values is actually
    #     implemented as a custom dropdown list with a predefined array of strings and values.
    #   * <tt>:auto</tt> - a powerful option which populates the dropdown list with all unique values of the field specified by 
    #     <tt>:attribute_name</tt> throughout all pages. In other words, this runs an SQL query without +offset+ and +limit+ clauses and
    #     with <tt>distinct(table.field)</tt> instead of <tt>distinct(*)</tt>
    #   * any other symbol name (method name) - The dropdown list is populated by all unique value returned by the method with this name 
    #     sent to <em>all</em> ActiveRecord objects throughout all pages. The main difference from <tt>:auto</tt> is that this method does
    #     not have to be a field in the result set, it is just some  value computed in the method after the database call and ActiveRecord
    #     instantiation.  
    #     But here lies the major drawback - this mode requires additional query without +offset+ and +limit+ clauses to instantiate _all_
    #     ActiveRecord objects, and performance-wise it brings all the advantages of pagination to nothing.
    #     Thus, memory- and performance-wise this can be really bad for some queries and tables and should be used with care.
    #   * An array of symbols (method names) - similar to the mode with a single symbol name. The first method name is sent to the ActiveRecord
    #     object if it responds to this method, the second method name is sent to the
    #     returned value unless it is +nil+, and so on. In other words, a single symbol mode is a
    #     case of an array of symbols where the array contains just one element. Thus the warning about the single method name 
    #     mode applies here as well.
    # * <tt>:boolean_filter_true_label</tt> - overrides the default value for <tt>BOOLEAN_FILTER_TRUE_LABEL</tt> ('+yes+') in the config. 
    #   Only has effect in a column with a boolean filter.
    # * <tt>:boolean_filter_false_label</tt> - overrides the default value for <tt>BOOLEAN_FILTER_FALSE_LABEL</tt> ('+no+') in the config. 
    #   Only has effect in a column with a boolean filter.
    # * <tt>:filter_all_label</tt> - overrides the default value for <tt>BOOLEAN_FILTER_FALSE_LABEL</tt> ('<tt>--</tt>') in the config. 
    #   Has effect in a column with a boolean filter _or_ a custom filter.
    # * <tt>:in_csv</tt> - When CSV export is enabled, all columns are included into the export. Setting <tt>:in_csv</tt> to false will
    #   prohibit the column from inclusion into the export.
    # * <tt>:in_html</tt> - When CSV export is enabled and it is needed to use a column for CSV export only and ignore it in HTML, set
    #   this parameter to false.
    #
    # The block parameter is an ActiveRecord instance. This block is called for every ActiveRecord shown, and the return value of 
    # the block is a string which becomes the contents of one table cell, or an array of two elements where the first element is the cell contents
    # and the second is a hash of HTML attributes to be added for the <tt><td></tt> tag of the current cell. 
    #
    # In case of an array output, please note that if you need to define HTML attributes for all <tt><td></tt>'s in a column, use +td_html_attrs+. 
    # Also note that if the method returns a hash with a <tt>:class</tt> or <tt>'class'</tt> element, it will not overwrite the class defined in
    # +td_html_attrs+, or classes added by the grid itself (+active_filter+ and +sorted+), instead they will be all concatenated: 
    # <tt><td class="sorted user_class_for_columns user_class_for_this_specific_cell"></tt>
    #
    # It is up to the developer to make sure that what in rendered in column cells
    # corresponds to sorting and filtering specified by parameters <tt>:attribute_name</tt> and <tt>:model_class</tt>.

    def column(opts = {}, &block)
      options = {
        :column_name => '', 
        :td_html_attrs => {}, 
        :model_class => nil, 
        :attribute_name => nil, 
        :no_filter => false, 
        :custom_filter => nil,
        :in_csv => true,
        :in_html => true,
        :boolean_filter_true_label  => Defaults::BOOLEAN_FILTER_TRUE_LABEL,
        :boolean_filter_false_label => Defaults::BOOLEAN_FILTER_FALSE_LABEL,
        :filter_all_label => Defaults::CUSTOM_FILTER_ALL_LABEL,
        :custom_order => nil
        }
        
      Wice.deprecated_call(:filter_options, :custom_filter, opts)
      Wice.deprecated_call(:column_label, :column_name, opts)
      Wice.deprecated_call(:td_html_options, :td_html_attrs, opts)
      
      options.merge!(opts)

      if options[:attribute_name].nil? and options[:model_class]
        raise WiceGridArgumentError.new("Option :model_class is only used together with :attribute_name") 
      end

      if options[:attribute_name] and options[:attribute_name].index('.')
        raise WiceGridArgumentError.new("Invalid attribute name #{options[:attribute_name]}. An attribute name must not contain a table name!") 
      end
      
      if block.nil? 
        if ! options[:attribute_name].blank?
          block = lambda{|obj| obj.send(options[:attribute_name])}
        else
          raise WiceGridArgumentError.new(
            "Missing column block without attribute_name defined. You can only omit the block if attribute_name is present.") 
        end
      end
    
      klass = ViewColumn
      # p "@grid.column_type #{options[:model_class]}"
      if options[:attribute_name] && 
          col_type_and_table_name = @grid.declare_column(options[:attribute_name], options[:model_class], 
            options[:custom_filter], options[:custom_order])

        db_column, table_name, main_table = col_type_and_table_name
        col_type = db_column.type
        klass = if options[:custom_filter]
          custom_filter = if options[:custom_filter] == :auto
             lambda{ @grid.distinct_values_for_column(db_column) } # Thank God Ruby has higher order functions!!!
          elsif options[:custom_filter].class == Symbol
            lambda{ @grid.distinct_values_for_column_in_resultset([options[:custom_filter]])}
          elsif options[:custom_filter].class == Array
            if options[:custom_filter].all_items_are_of_class(Symbol)
              lambda{ @grid.distinct_values_for_column_in_resultset(options[:custom_filter]) }
            elsif options[:custom_filter].all_items_are_of_class(String)
              # leave like they are, fine
              options[:custom_filter]
            else
              raise WiceGridArgumentError.new(
                ':custom_filter can equal :auto, a homogeneous array of strings (direct values for the dropdown), ' + 
                'a homogeneous array of symbols (a sequence of methods to send to AR objects in the result set to ' +
                'retrieve unique values for the dropdown), or a Symbol (a shortcut for a one member array of symbols).')
            end
          end
          
          ViewColumnCustomDropdown
        else
          ViewColumn.handled_type[col_type] || ViewColumn
        end
      end

    
      vc = klass.new(options[:attribute_name], options[:column_name], options[:td_html_attrs], block)
      vc.grid = @grid
      vc.no_filter      = options[:no_filter]
      vc.table_name     = table_name
      vc.model_class    = options[:model_class]
      vc.main_table     = main_table
      vc.custom_filter  = custom_filter
      vc.in_html        = options[:in_html]
      vc.in_csv         = options[:in_csv]
      
      vc.filter_all_label = options[:filter_all_label] if vc.kind_of?(ViewColumnCustomDropdown)
      if vc.kind_of?(ViewColumnBoolean)
        vc.boolean_filter_true_label = options[:boolean_filter_true_label]
        vc.boolean_filter_false_label = options[:boolean_filter_false_label]
      end
      @columns << vc
    end
    
    
    # Optional method inside the +grid+ block, to which every ActiveRecord instance is injected, just like +column+. Unlike +column+, it returns
    # a hash which will be used as HTML attributes for the row with the given ActiveRecord instance.
    #
    # Note that if the method returns a hash with a <tt>:class</tt> or <tt>'class'</tt> element, it will not overwrite classes +even+ and +odd+,
    # instead they will be concatenated: <tt><tr class="even highlighted_row_class_name"></tt>
    def row_attributes(&block)
      @row_attributes_handler = block
    end

    def get_row_attributes(ar_object) #:nodoc:
      if @row_attributes_handler
        @row_attributes_handler.call(ar_object)
      else
        {}
      end
    end

  
    def no_filter_needed?   #:nodoc:
      not @columns.inject(false){|a,b| a || b.filter_shown? }
    end

    def base_link_for_filter(controller, extra_parameters = {})   #:nodoc:
      new_params = controller.params.deep_clone_yl
      new_params.merge!(extra_parameters)
      
      if new_params[@grid.name]
        new_params[@grid.name].delete(:page) # we reset paging here
        new_params[@grid.name].delete(:f)
      end

      new_params[:only_path] = false
      controller.url_for(new_params)
    end

    def link_for_export(controller, format, extra_parameters = {})   #:nodoc:
      new_params = controller.params.deep_clone_yl
      new_params.merge!(extra_parameters)
      
      new_params[@grid.name] = {} unless new_params[@grid.name]
      new_params[@grid.name][:export] = format      
      
      new_params[:only_path] = false
      controller.url_for(new_params)
    end


    def column_link(column, direction, params, extra_parameters = {})   #:nodoc:

      column_attribute_name = if column.attribute_name.index('.') or column.main_table
        column.attribute_name
      else
        column.table_name + '.' + column.attribute_name
      end

      query_params = {@grid.name => {
        @@order_parameter_name => column_attribute_name, 
        @@order_direction_parameter_name => direction
      }}

      cleaned_params =  params.deep_clone_yl
      cleaned_params.merge!(extra_parameters)
      
      cleaned_params.delete(:controller)
      cleaned_params.delete(:action)
    
    
      query_params = cleaned_params.rec_merge(query_params)

      '?' + query_params.to_query
    end   
    
    protected
    
    def filter_columns(method_name) #:nodoc:
      method_name ? @columns.select(&method_name) : @columns
    end
    

  end
end