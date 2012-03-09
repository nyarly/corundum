require 'mattock/configuration-store'
module Corundum
  def self.configuration_store
    @configuration_store ||=
      Mattock::ConfigurationStore.new("corundum",
                                      File::expand_path("../default_configuration", __FILE__))
  end

  def self.register_project(rakefile)
    configuration_store.register_search_path(rakefile)
  end

  def self.user_preferences
    configuration_store.user_preferences
  end
end
