require 'valise'

module Corundum
  class ConfigurationStore
    def initialize
      @valise = Valise::Set.define do
        rw "~/.corundum"
        rw "/usr/share/corundum"
        rw "/etc/corundum"
        ro from_here("default_configuration")

        handle "preferences.yaml", :yaml, :hash_merge
      end

      @loaded ||= Hash.new{|h,k| h[k] = @valise.find(k).contents}
    end

    attr_reader :loaded

    def register_search_path(from_file)
      directory = File::dirname(from_file)
      @valise.prepend_search_root(Valise::SearchRoot.new(directory))
      loaded.clear
    end
  end

  def self.configuration_store
    @configuration_store ||= ConfigurationStore.new
  end

  def self.register_project(rakefile)
    configuration_store.register_search_path(rakefile)
  end

  def self.user_preferences
    configuration_store.loaded["preferences.yaml"]
  end
end
