class Spree::Admin::AuctionSettingsController < Spree::Admin::BaseController
  def edit
    @config = Spree::AuctionSettings::Config
  end

  def update
    config = Spree::AuctionSettings::Config

    params.each do |name, value|
      next unless config.has_preference? name
      config[name] = value
    end

    redirect_to edit_admin_auction_settings_path
  end
end
