class AddCheckoutTimeMinutesToSpreeAuctions < ActiveRecord::Migration[5.1]
  def change
    add_column :spree_auctions, :checkout_time_minutes, :integer, default: 1440
  end
end
