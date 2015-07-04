require 'optparse'
require 'corundum/configuration-store'
require 'rake/application'

module Corundum
  module CLI
    class Skelfiles
      class Skelfile
        def initialize(source, target, exclude)
          @source, @target, @exclude = source, target, exclude
          @message = "No attempt to create yet"
        end
        attr_reader :source, :target, :exclude, :message

        def templates
          Corundum.configuration_store.valise.templates("skel-files")
        end

        def create!(scope)
          unless (found = exclude.map{|pattern| Dir.glob(pattern)}.flatten).empty?
            @message = "Refusing to clobber existing '#{found.first}'"
          else
            File::open(target, "w") do |file|
              contents = templates.contents(source)
              case contents
              when Tilt::Template
                file.write(contents.render(scope, {}))
              else
                file.write(contents)
              end
            end
            @message = "Created #{target}"
          end
        end
      end

      def initialize(args)
        @args = args
      end
      attr_reader :args

      SkelfileScope = Struct.new(:project_name)

      def options
        @options ||= OptionParser.new do |opti|
          opti.banner = "Spits on skeleton files to start a gem with.\nUsage: #$0 [options]"
          opti.on("-h", "--help", "This help message") do
            puts opti
            puts "Will emit these files:"
            puts skelfiles.map{|desc| desc.target}.join(", ")
            puts
            puts "Files are copied from the skel-files directory out of this search path:"
            puts Corundum.configuration_store.valise
            exit 0
          end

          opti.on("-p", "--project NAME", "Sets the name of the project (defaults to dirname, i.e. '#{default_project_name}')") do |name| #ok
            scope.project_name = name
          end
        end
      end

      def default_project_name
        File.basename(Dir.pwd)
      end

      def scope
        @scope ||= SkelfileScope.new(default_project_name)
      end

      def skelfiles
        @skelfiles ||= [
          Skelfile.new( 'rakefile',   'Rakefile',                       Rake::Application::DEFAULT_RAKEFILES),
          Skelfile.new( 'simplecov',  '.simplecov',                     %w[.simplecov] ),
          Skelfile.new( 'travis',     '.travis.yml',                    %w[.travis.yml] ),
          Skelfile.new( 'gemspec',    "#{scope.project_name}.gemspec",  %w{gemspec.rb *.gemspec} ),
          Skelfile.new( 'gemfile',    'Gemfile',                        %w[Gemfile] )
        ]
      end

      def parse_args
        options.parse(args)
      end

      def go
        parse_args

        skelfiles.each do |skelfile|
          skelfile.create!(scope)
          puts skelfile.message
        end
      end
    end
  end
end
