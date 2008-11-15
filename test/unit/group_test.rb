require File.dirname(__FILE__) + '/../test_helper'

class GroupTest < Test::Unit::TestCase
  fixtures :groups
  
  def setup
    @group = Group.find(:first)
    #@tom = User.find 1
    #@ben = User.find 2
  end
  
  def test_joining_group
    assert(@group)
   # 
   # assert(!@group.users.exists?(@ben))
   # assert(@group.join(@ben))
   # assert(@group.users.exists?(@ben))
  end
  
  #def test_leaving_group
  #  assert(!@group.leave(nil))
  #  
  #  assert(@group.users.exists?(@tom))
  #  assert(@group.leave(@tom))
  #  assert(!@group.users.exists?(@tom))
  #end
end
