module SolidusAuctionNew
  class Configuration < Spree::Preferences::Configuration
    preference :starting_soon_hours, :integer, default: 24
    preference :ending_soon_hours, :integer, default: 3
    preference :recently_completed_hours, :integer, default: 24
    preference :number_of_bids_to_show, :integer, default: 5
  end
end
