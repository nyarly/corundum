require 'corundum'

require 'corundum/documentation/assembly'
require 'corundum/documentation/yardoc'
require 'corundum/documentation/github-pages'
require 'corundum/documentation/email'

Corundum.configuration_store.valise.add_search_root(
  Valise::SearchRoot.new( Valise::Unpath.from_here("default_configuration") )
)
