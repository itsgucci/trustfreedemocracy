module Badges
  class InstallManager
    class << self
      
      def install
        setup
        migrate :up
      rescue Object => exception
        puts "Badges plugin install error:\n#{exception.message}\n" + exception.backtrace.join("\n\t")
        raise $!
      end
      
      def uninstall
        setup
        migrate :down
      rescue Object => exception
        puts "Badges plugin uninstall error:\n#{exception.message}\n" + exception.backtrace.join("\n\t")
        raise $!
      end

      private
      
      def setup
        load File.join(RAILS_ROOT, 'config', 'environment.rb')
        ActiveRecord::Base.connection.initialize_schema_information
        raise StandardError.new("This database does not yet support installations") unless ActiveRecord::Base.connection.supports_migrations?
      end
      
      def migrate direction
        installation_classes(direction).each do |(version, installation_class)|
          ActiveRecord::Base.logger.info "Installing to #{installation_class} (#{version})"
          installation_class.migrate(direction)
        end
      end

      def installation_classes direction
        file_list = (direction == :down) ? installation_files.reverse : installation_files
        installations = installation_files.inject([]) do |installations, installation_file|
          installations = [] if installations.nil?
          load(installation_file)
          version, name = installation_version_and_name(installation_file)
          assert_unique_installation_version(installations, version.to_i)
          installations << [ version.to_i, installation_class(name) ]
        end

        (direction == :down) ? installations.sort.reverse : installations.sort
      end

      def assert_unique_installation_version(installations, version)
        if !installations.nil? && !installations.empty?
          if installations.transpose.first.include?(version)
            raise "Duplicate Installation Version Error:" + version
          end
        end
      end

      def installation_files
        files = Dir["#{File.dirname(__FILE__)}/db/migrate/[0-9]*_*.rb"].sort_by do |f|
          installation_version_and_name(f).first.to_i
        end
      end

      def installation_class(installation_name)
        installation_name.camelize.constantize
      end

      def installation_version_and_name(installation_file)
        return *installation_file.scan(/([0-9]+)_([_a-z0-9]*).rb/).first
      end
      
    end
  end
end