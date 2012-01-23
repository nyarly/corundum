require 'corundum/tasklib'

#Big XXX: this totally isn't done.  It's some notes against ever wanting to
#publish announcements to rubyforge ever again

module Corundum
  class Publishing < TaskLib
    default_namespace :rubyforge

    setting(:rubyforge,  nested(:package_id => nil, :group_id => nil, :release_name => nil))
    setting(:package_dir,  nil)
    setting(:gemspec,  nil)

    def define
      desc "Publish the gem and its documentation to Rubyforge and Gemcutter"
      task root_task => in_namespace(:docs, :rubyforge)

      in_namespace do
        desc 'Publish RDoc to RubyForge'
        task :docs do
          config = YAML.load(File.read(File.expand_path("~/.rubyforge/user-config.yml")))
          host = "#{config["username"]}@rubyforge.org"
          remote_dir = "/var/www/gforge-projects/#{@rubyforge[:group_id]}"
          local_dir = 'rubydoc'
          sh %{rsync -av --delete #{local_dir}/ #{host}:#{remote_dir}}
        end

        task :scrape_rubyforge do
          require 'rubyforge'
          forge = RubyForge.new
          forge.configure
          forge.scrape_project(@rubyforge[:package_id])
        end

        desc "Publishes to RubyForge"
        task :rubyforge => [:docs, :scrape_rubyforge] do |t|
          require 'rubyforge'
          forge = RubyForge.new
          forge.configure
          files = [".gem", ".tar.gz", ".tar.bz2"].map do |extension|
            File::join(@package_dir, @gemspec.full_name) + extension
          end
          release = forge.lookup("release", @rubyforge[:package_id])[@rubyforge[:release_name]] rescue nil
          if release.nil?
            forge.add_release(@rubyforge[:group_id], @rubyforge[:package_id], @rubyforge[:release_name], *files)
          else
            files.each do |file|
              forge.add_file(@rubyforge[:group_id], @rubyforge[:package_id], @rubyforge[:release_name], file)
            end
          end
        end
      end
    end
  end
end
