# ActsAsVoteable
module Juixe
  module Acts #:nodoc:
    module Voteable #:nodoc:

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_voteable
          has_many :votes, :as => :voteable, :dependent => :destroy
          include Juixe::Acts::Voteable::InstanceMethods
          extend Juixe::Acts::Voteable::SingletonMethods
        end
      end
      
      # This module contains class methods
      module SingletonMethods
        def find_votes_cast_by_user(user)
          voteable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          Vote.find(:all,
            :conditions => ["user_id = ? and voteable_type = ?", user.id, voteable],
            :order => "created_at DESC"
          )
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        def votes_for
          votes = Vote.find(:all, :conditions => [
            "voteable_id = ? AND voteable_type = ? AND vote = ?",
            id, self.type.name, true
          ])
          votes.size
        end
        
        def votes_against
          votes = Vote.find(:all, :conditions => [
            "voteable_id = ? AND voteable_type = ? AND vote = ?",
            id, self.type.name, false
          ])
          votes.size
        end
        
        def has_voted?(user)
          Vote.exists?(['voteable_id = ? AND voteable_type = ? AND user_id = ?', id, self.type.name, user.id])
        end
        
        # Same as voteable.votes.size
        def votes_count
          self.votes.size
        end
        
        def users_who_voted
          users = []
          self.votes.each { |v|
            users << v.user
          }
          users
        end
        
        def voted_by_user?(user)
          if user
            self.votes.each { |v|
              return true if user.id == v.user_id
            }
          end
          return false
        end
      end
    end
  end
end
