module Wice #:nodoc:
  class TableColumnMatrix < Hash #:nodoc:

    def initialize()  #:nodoc:
      super
      @by_table_names = HashWithIndifferentAccess.new
      @columns_requested_by_the_view = []
    end
  
    alias_method :get, :[]
  
    attr_reader :default_model_class
    def default_model_class=(model_klass)  #:nodoc:
      init_columns_of_table(model_klass) unless has_key?(model_klass)
      @default_model_class = model_klass
    end

    def [](model_klass)  #:nodoc:
      init_columns_of_table(model_klass) unless has_key?(model_klass)
      get(model_klass)
    end
  
    def get_column_by_model_class_and_column_name(model_class, column_name)  #:nodoc:
      self[model_class][column_name]
    end
  
    def get_column_in_default_model_class_by_column_name(column_name)  #:nodoc:
      raise WiceGridException.new("Cannot search for a column in a default model as the default model is not set") if @default_model_class.nil?
      self[@default_model_class][column_name]    
    end

    # no autoinitialization !!!
    def get_column_by_table_name_and_column_name(table_name, column_name)  #:nodoc:
      if @by_table_names[table_name]
        @by_table_names[table_name][column_name]
      else
        false
      end
    end

    # no autoinitialization !!!
    def get_column_by_fully_qualified_column_name(name) #:nodoc:
      chunks = name.split('.')
      if chunks.size == 1
        if @default_model_class
          column_name = chunks[0]
          table_name = @default_model_class.table_name
        else
          raise WiceGridException.new("Cannot identify column without the default table or a fully qualified table name")
        end
      else
        column_name = chunks[1]
        table_name  = chunks[0]
      end
      get_column_by_table_name_and_column_name(table_name, column_name)
    end
  
    def add_column_requested_by_the_view(column) #:nodoc:
      @columns_requested_by_the_view << column
    end
  
    attr_reader  :columns_requested_by_the_view

  
    def init_columns_of_table(model_klass) #:nodoc:
      # puts "init_columns_of_table #{model_klass}"
      self[model_klass] = HashWithIndifferentAccess.new(model_klass.columns.index_by(&:name))
      @by_table_names[model_klass.table_name] = self[model_klass] 
      self[model_klass].each_value{|c| c.model_klass = model_klass}
    end
    alias_method :<< , :init_columns_of_table
  
  end
end