require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups(assets: %w(development test)))


begin
  require 'spree_frontend'
rescue LoadError
  # spree_frontend is not available.
end
      
begin
  require 'spree_backend'
rescue LoadError
  # spree_backend is not available.
end
      
begin
  require 'spree_api'
rescue LoadError
  # spree_api is not available.
end
      require 'solidus_auction'

module Dummy
  class Application < Rails::Application
    
    config.to_prepare do
      # Load application's model / class decorators
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      # Load application's view overrides
      Dir.glob(File.join(File.dirname(__FILE__), "../app/overrides/*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end


