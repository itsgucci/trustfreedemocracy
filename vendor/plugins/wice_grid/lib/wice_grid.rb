require 'wice_grid_config.rb'
require 'core_ext.rb'
require 'grid_renderer.rb'
require 'table_column_matrix.rb'
require 'view_helper.rb'
require 'view_columns.rb'
require 'controller.rb'
require 'spreadsheet_wrapper.rb'

module Wice
  
  def self.deprecated_call(old_name, new_name, opts) #:nodoc:
    # opts = opts.dup
    if opts[old_name] && ! opts[new_name]
      opts[new_name] = opts[old_name]
      opts.delete(old_name)
      puts "WiceGrid: Parameter :#{old_name} is deprecated, use :#{new_name} instead!"
    end      
  end
  
  def self.log(message) #:nodoc:
    ActiveRecord::Base.logger.info('WiceGrid: ' + message)
  end  
  
  class WiceGridArgumentError < ArgumentError #:nodoc:
  end 
  class WiceGridException < Exception #:nodoc:
  end 

  class WiceGrid #:nodoc:

    attr_reader :klass, :name, :resultset, :custom_order
  
    attr_reader :ar_options, :status, :export_to_csv_enabled, :csv_file_name


    def initialize(klass, controller, opts = {})  #:nodoc:
      
      @controller = controller
      raise WiceGridArgumentError.new("ActiveRecord model class (second argument) must be a Class derived from ActiveRecord::Base") unless klass.kind_of? Class and klass.ancestors.index(ActiveRecord::Base)
      raise WiceGridException.new("Plugin will_paginate not found! wice_grid requires will_paginate.") unless klass.respond_to?(:paginate)    

      opts[:order_direction].downcase! if opts[:order_direction].kind_of?(String)
      if opts[:order_direction] and not (opts[:order_direction] == 'asc' or opts[:order_direction] == :asc or 
          opts[:order_direction] == 'desc' or opts[:order_direction] == :desc)
        raise WiceGridArgumentError.new(":order_direction must be either 'asc' or 'desc'.")
      end
    
      # options that are understood
      @options = {
        :erb_mode => Defaults::ERB_MODE,
        :per_page => Defaults::PER_PAGE,
        :order_direction => Defaults::ORDER_DIRECTION, 
        :name => Defaults::GRID_NAME,
        :enable_export_to_csv => Defaults::ENABLE_EXPORT_TO_CSV,
        :csv_file_name => nil,
        :columns => nil, 
        :order => nil, 
        :page => 1, 
        :joins => nil, 
        :include => nil, 
        :conditions => nil,
        :custom_order => {}
      }
      @options.merge!(opts)
      @export_to_csv_enabled = @options[:enable_export_to_csv]
      @csv_file_name = @options[:csv_file_name]
      
      @name = @options[:name].to_s
      raise WiceGridArgumentError.new("name of the grid should be a string or a symbol") unless name.kind_of? String or name.kind_of? Symbol      
      raise WiceGridArgumentError.new("name of the grid can only contain alphanumeruc characters") unless @name =~ /^\w[\w\d_]*$/    

      @klass = klass

      @table_column_matrix = TableColumnMatrix.new
      @table_column_matrix.default_model_class = @klass
    
    
      @ar_options = {}
      @status = HashWithIndifferentAccess.new
        
      if @options[:order] 
        @options[:order] = @options[:order].to_s
        @options[:order_direction] = @options[:order_direction].to_s
      
      
        @status[:order_direction] = @options[:order_direction]
        @status[:order] = @options[:order]
      
      end
      @status[:per_page] = @options[:per_page]
      @status[:page] = @options[:page]
      @status[:conditions] = @options[:conditions]
      @status[:f] = @options[:f]

      process_params

      @ar_options_formed = false

    end
  
  
    def declare_column(column_name, model_class, custom_filter, custom_order)  #:nodoc:
        
      if model_class # this is an included table
        column = @table_column_matrix.get_column_by_model_class_and_column_name(model_class, column_name)
        raise WiceGridArgumentError.new("Сolumn '#{column_name}' is not found in table '#{model_class.table_name}'!") if column.nil?
        main_table = false
        table_name = model_class.table_name
      else
        column = @table_column_matrix.get_column_in_default_model_class_by_column_name(column_name)
        raise WiceGridArgumentError.new("Сolumn '#{column_name}' is not found in table '#{@klass.table_name}'! If '#{column_name}' belongs to another table you should declare it in :include or :join when initialising the grid, and specify :model_class in column declaration.") if column.nil?        

        main_table = true
        table_name = @table_column_matrix.default_model_class.table_name
      end


      # custom_filter might be a complex object, and I want true/false/nil only in column.custom_filter
      column.custom_filter = true if custom_filter 
      column.custom_order = custom_order unless custom_order.blank?
                
      if column
        column.initialize_request_parameters(@status[:f], main_table)
        if @status[:f] and column.conditions.blank?
          @status[:f].delete(column.current_parameter_name)           
        end
      
        @table_column_matrix.add_column_requested_by_the_view(column)
        [column, table_name , main_table]
      else
        nil
      end
    end
  
    def filter_params(view_column)  #:nodoc:
      column_name = view_column.fully_qualified_attribute_name
      if @status[:f] and @status[:f][column_name]
        @status[:f][column_name] 
      else
        {}
      end
    end

    def resultset  #:nodoc:
      self.read unless @resultset # database querying is late!
      @resultset
    end
  
    def each   #:nodoc:
      self.read unless @resultset # database querying is late!
      @resultset.each do |r|
        yield r
      end
    end
  
    def erb_mode?  #:nodoc:
      @options[:erb_mode]
    end
  
    def ordered_by?(column)  #:nodoc:
      return nil if @status[:order].blank?
      if column.main_table      
        if offs = @status[:order].index('.')
          @status[:order][(offs+1)..-1] == column.attribute_name
        else
          @status[:order] == column.attribute_name
        end
      else
        @status[:order] == column.table_name + '.' + column.attribute_name
      end
    end

    def ordered_by  #:nodoc:
      @status[:order]
    end

  
    def order_direction  #:nodoc:
      @status[:order_direction]
    end
  
    def filtering_on?  #:nodoc:
      not @status[:f].blank?
    end
  
    def filtered_by  #:nodoc:
      @status[:f].nil? ? [] : @status[:f].keys
    end
  
    def filtered_by?(view_column)  #:nodoc:
      @status[:f].nil? ? false : @status[:f].has_key?(view_column.fully_qualified_attribute_name)
    end
  
  
    def count  #:nodoc:
      form_ar_options    
      @klass.count(:conditions => @ar_options[:conditions], :joins => @ar_options[:joins], :include => @ar_options[:include])
    end
    
    alias_method :size, :count
    
    def distinct_values_for_column(column)  #:nodoc:
      column.model_klass.find(:all, :select => 'distinct ' + column.name).collect{|ar| ar.send(column.name) }.reject(&:blank?)
    end


    # TO DO: optimize - this is extremely resource hungry - retrieves all (without paging) objects into memory, with all attributes
    def distinct_values_for_column_in_resultset(messages)  #:nodoc:
      uniq_vals = Set.new

      resultset_without_paging.each do |ar|        
        v = ar.deep_send(*messages)
        uniq_vals << v unless v.nil?
      end
      return uniq_vals.to_a
    end


    # not finished
    def uniq_values_of_column_in_resultset(field_name)  #:nodoc:
      form_ar_options
      
      @klass.find(:all, 
        :select => 'distinct ' + field_name,
        :joins => @ar_options[:joins], 
        :include => @ar_options[:include], 
        :conditions => @options[:conditions])
    end
    
        
    def empty?  #:nodoc:
      self.count == 0
    end
  
    def output_csv?
      @status[:export] == 'csv'
    end

    def output_html?
      @status[:export].blank?
    end
  
    protected

    def process_params  #:nodoc:
      if params[name]
        @status.merge!(params[name])
        @status.delete(:export) unless self.export_to_csv_enabled
      end
    end

    def string_conditions_to_array_cond(o)  #:nodoc:
      if o.kind_of? Array
        o
      else
        [o]
      end
    end

    def unite_conditions(c1, c2)  #:nodoc:
      return c2 if c1.blank?
      c1 = string_conditions_to_array_cond(c1)
      c2 = string_conditions_to_array_cond(c2)
      c1[0] += ' and ' + c2[0]
      c1 << c2[1..-1]
      c1.flatten
    end
  

    def form_ar_options  #:nodoc:
      return if @ar_options_formed
      @ar_options_formed = true
      
      @ar_options[:conditions] = @status[:conditions]
    
      @status.delete(:f) if @table_column_matrix.columns_requested_by_the_view.size == 0
      
      @table_column_matrix.columns_requested_by_the_view.each do |table_column|
        if table_column.conditions
          @ar_options[:conditions] = unite_conditions(@ar_options[:conditions], table_column.conditions)
        end
      end
      

      if @status[:order]
        @ar_options[:order] = add_custom_order_sql(complete_column_name(@status[:order]))
        
        @ar_options[:order] += ' ' + @status[:order_direction]
      end
      if self.output_html?
        @ar_options[:per_page] = @status[:per_page]
        @ar_options[:page] = @status[:page]
      end

      @ar_options[:joins]   = @options[:joins]
      @ar_options[:include] = @options[:include]
    end

    def add_custom_order_sql(fully_qualified_column_name)
      custom_order = if @options[:custom_order].has_key?(fully_qualified_column_name)
        @options[:custom_order][fully_qualified_column_name]
      else
        @table_column_matrix.get_column_by_fully_qualified_column_name(fully_qualified_column_name).custom_order
      end 
      
      if custom_order.blank?
        fully_qualified_column_name
      else
        if custom_order.is_a? String
          custom_order.gsub(/\?/, fully_qualified_column_name)
        elsif custom_order.is_a? Proc
          custom_order.call(fully_qualified_column_name)
        else
          raise WiceGridArgumentError.new("invalid custom order #{custom_order.inspect}")
        end
      end
    end

    def complete_column_name(col_name)  #:nodoc:
      if col_name.index('.') # already has a table name
        col_name
      else # add the default table
        "#{@klass.table_name}.#{col_name}"
      end
    end

    def params  #:nodoc:
      @controller.params
    end

    def read  #:nodoc:
      form_ar_options    
      # Wice.log(@ar_options.to_yaml)
      @resultset = self.output_csv? ?  @klass.find(:all, @ar_options) : @klass.paginate(@ar_options)
      @resultset
    end
    
    def resultset_without_paging  #:nodoc:
      form_ar_options
      @klass.find(:all, :joins => @ar_options[:joins], :include => @ar_options[:include], :conditions => @options[:conditions])
    end


  end
end

module ActiveRecord #:nodoc:
  module ConnectionAdapters #:nodoc:
    class Column #:nodoc:
      
      attr_accessor :model_klass, :custom_filter, :custom_order
      attr_reader :current_parameter_name, :conditions
      
      
      def initialize_request_parameters(all_filter_params, main_table)  #:nodoc:
        @request_params = nil
        @conditions = nil
        return if all_filter_params.nil?
        
        # if the parameter does not specify the table name we only allow columns in the default table to use these parameters
        if main_table && @request_params  = all_filter_params[self.name]
          @current_parameter_name = self.name
        elsif @request_params = all_filter_params[@model_klass.table_name + '.' + self.name]
          @current_parameter_name = @model_klass.table_name + '.' + self.name
        end

        if @request_params
          if self.type == :datetime
            @request_params[:fr] = Column.params_2_datetime(@request_params[:fr]) if @request_params[:fr]
            @request_params[:to] = Column.params_2_datetime(@request_params[:to]) if @request_params[:to]
          end
          
          if self.type == :date
            @request_params[:fr] = Column.params_2_date(@request_params[:fr]) if @request_params[:fr]
            @request_params[:to] = Column.params_2_date(@request_params[:to]) if @request_params[:to]
          end
        end
        @conditions = generate_conditions
      end
      
      def generate_conditions  #:nodoc:
        return nil if @request_params.nil?
        
        if @custom_filter
          return generate_conditions_custom_filter_options(@request_params) 
        end
        method_name = 'generate_conditions_' + self.type.to_s
        if self.respond_to?(method_name)
          return self.send('generate_conditions_' + self.type.to_s, @request_params)
        else
          nil
        end
      end
      
      protected
      def  generate_conditions_string(opts)   #:nodoc:
        unless opts.kind_of? String
          Wice.log "invalid parameters for the grid string filter - must be a string: #{opts.inspect}" 
          return false 
        end
        if opts.empty?
          Wice.log "invalid parameters for the grid string filter - empty string" 
          return false 
        end
        return [" #{model_klass.table_name}.#{self.name} like ?", '%' + opts + '%']
      end
      
      alias_method :generate_conditions_text, :generate_conditions_string

      def  generate_conditions_custom_filter_options(opts)   #:nodoc:
        if opts.empty?
          Wice.log "empty parameters for the grid custom filter" 
          return false 
        end
        if opts.kind_of?(Array)
          [" #{model_klass.table_name}.#{self.name} IN ( " + (['?'] * opts.size).join(', ') + ' )'] + opts
        else
          [" #{model_klass.table_name}.#{self.name} = ?", opts]
        end
      end

      
      def  generate_conditions_decimal(opts)   #:nodoc:
        generate_conditions_integer(opts)
      end
      
      def  generate_conditions_integer(opts)   #:nodoc:
        unless opts.kind_of? Hash
          Wice.log "invalid parameters for the grid integer filter - must be a hash" 
          return false 
        end
        conditions = [[]]
        if opts[:fr] 
          if opts[:fr] =~ /\d/
            conditions[0] << " #{model_klass.table_name}.#{self.name} >= ? "
            conditions << opts[:fr]
          else
            opts.delete(:fr)
          end
        end

        if opts[:to]
          if opts[:to] =~ /\d/
            conditions[0] << " #{model_klass.table_name}.#{self.name} <= ? "
            conditions << opts[:to]
          else
            opts.delete(:to)
          end
        end
        
        if conditions.size == 1
          Wice.log "invalid parameters for the grid integer filter - either range limits are not supplied or they are not numeric" 
          return false
        end
        
        conditions[0] = conditions[0].join(' and ')
        
        return conditions
      end

      def  generate_conditions_boolean(opts)   #:nodoc:
        unless (opts.kind_of?(Array) && opts.size == 1)
          Wice.log "invalid parameters for the grid boolean filter - must be an one item array: #{opts.inspect}" 
          return false 
        end
        opts = opts[0]
        if opts == 'f'
          [" #{model_klass.table_name}.#{self.name} = ? or #{model_klass.table_name}.#{self.name} is null ", false]
        elsif opts == 't'
          [" #{model_klass.table_name}.#{self.name} = ?", true]
        else
          nil
        end
      end

      def  generate_conditions_datetime(opts)  #:nodoc: 
        generate_conditions_date(opts)
      end
      
      def generate_conditions_date(opts)   #:nodoc:
        conditions = [[]]
        if opts[:fr]
          conditions[0] << " #{model_klass.table_name}.#{self.name} >= ? "
          conditions << opts[:fr]          
        end

        if opts[:to]
          conditions[0] << " #{model_klass.table_name}.#{self.name} <= ? "
          conditions << opts[:to]  
        end
        
        return false if conditions.size == 1
        
        conditions[0] = conditions[0].join(' and ')
        return conditions
      end


      def self.params_2_datetime(par)   #:nodoc:
        return nil if par.blank?
        params =  [par[:year], par[:month], par[:day], par[:hour], par[:minute]].collect{|v| v.blank? ? nil : v.to_i}
        Time.local(*params)
      end

      def self.params_2_date(par)   #:nodoc:
        return nil if par.blank?
        params =  [par[:year], par[:month], par[:day]].collect{|v| v.blank? ? nil : v.to_i}
        Date.civil(*params)
      end
    end
  end
end


