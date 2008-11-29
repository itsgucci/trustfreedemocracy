require 'csv'

module Wice
  class Spreadsheet  #:nodoc:
    def initialize(name)  #:nodoc:
      @tempfile = Tempfile.new(name)
    end
  
    def << (row)  #:nodoc:
      CSV::Writer.generate(@tempfile) do |csv|
         csv << row.map(&:to_s)
      end    
    end
  
    def to_csv  #:nodoc:
      self.close
      File.readlines(@tempfile.path).join('')
    end
  
    def path  #:nodoc:
      @tempfile.path
    end
    
    def close  #:nodoc:
      @tempfile.close
    end
  end
end
