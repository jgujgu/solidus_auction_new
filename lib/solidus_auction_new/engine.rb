module SolidusAuctionNew
  class Engine < Rails::Engine
    require 'spree/core'
    require 'acts_as_votable'
    isolate_namespace Spree
    engine_name 'solidus_auction_new'
    config.autoload_paths += %W(#{config.root}/lib)

    initializer 'solidus_auction_new.environment', before: :load_config_initializers do
      Spree::AuctionSettings::Config = SolidusAuctionNew::Configuration.new
    end

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      Dir.glob(File.join(File.dirname(__FILE__), "../../app/overrides/*.rb")) do |c|
                Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end

module Spree::AuctionSettings
end
