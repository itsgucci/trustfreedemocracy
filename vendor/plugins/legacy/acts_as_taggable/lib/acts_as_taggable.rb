module ActiveRecord
  module Acts #:nodoc:
    module Taggable #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)  
      end

      module ClassMethods
        def acts_as_taggable(options = {})
          write_inheritable_attribute(:acts_as_taggable_options, {
            :taggable_type => ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s,
            :from => options[:from]
            })

            class_inheritable_reader :acts_as_taggable_options

            has_many :taggings, :as => :taggable, :dependent => :destroy
            has_many :tags, :through => :taggings

            include ActiveRecord::Acts::Taggable::InstanceMethods
            extend ActiveRecord::Acts::Taggable::SingletonMethods          
          end
        end

        module SingletonMethods
          def find_tagged_with(list)
            find_by_sql([
              "SELECT #{table_name}.* FROM #{table_name}, tags, taggings " +
              "WHERE #{table_name}.#{primary_key} = taggings.taggable_id " +
              "AND taggings.taggable_type = ? " +
              "AND taggings.tag_id = tags.id AND tags.name IN (?)",
              acts_as_taggable_options[:taggable_type], list
            ])
          end
		  def find_tagged_by_id(list)
            find_by_sql([
              "SELECT #{table_name}.* FROM #{table_name}, tags, taggings " +
              "WHERE #{table_name}.#{primary_key} = taggings.taggable_id " +
              "AND taggings.taggable_type = ? " +
              "AND taggings.tag_id = tags.id AND tags.id IN (?)",
              acts_as_taggable_options[:taggable_type], list
            ])
          end
        end
            

            module InstanceMethods
              def tag_with(list)
               Tag.transaction do
                #taggings.destroy_all
				Tag.parse(list).each do |name|
				  if acts_as_taggable_options[:from]
				    send(acts_as_taggable_options[:from]).tags.find_or_create_by_name(name).on(self)
				  else
                         Tag.find_or_create_by_name(name).on(self)
                      end
                   end
                end
              end

              def tag_list(seperator = ", ")
                #tags.collect { |tag| tag.name.include?(" ") ? "'#{tag.name}'" : tag.name }.join(seperator)
                tags.join(seperator)
              end
              
              
              def top_four_tags
                top_n_tag_list 4
              end
              def top_two_tags
                top_n_tag_list 2
              end
              #
              def top_n_tag_list(n, seperator = ", ")
                top_n_tags(n).join(seperator)
              end
              
              def top_n_tags(n)
                tags.inject(Hash.new(0)) {|h,x| h[x.name]+=1;h}.sort { |a, b| b[1] <=> a[1] }[0..n - 1].map { |x| x[0] }
              end

            end
          end
        end
      end