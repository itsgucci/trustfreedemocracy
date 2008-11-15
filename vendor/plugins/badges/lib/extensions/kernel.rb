module Kernel
  def singleton_class
    class << self; self; end
  end
end