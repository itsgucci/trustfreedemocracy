module Badges
  def self.thread_current_user
    Thread.current['current_user'] || nil
  end

  def self.thread_current_user=(user)
    Thread.current['current_user'] = user
  end
end