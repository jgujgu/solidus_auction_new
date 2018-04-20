# This migration comes from solidus_auction (originally 20180320010358)
class ChangeAuctionReservePriceColumnToBigDecimal < ActiveRecord::Migration[5.1]
  def change
    change_column :spree_auctions, :reserve_price, :decimal, precision: 12, scale: 2
    change_column :spree_auctions, :current_price, :decimal, precision: 12, scale: 2
    change_column :spree_auctions, :bid_increment, :decimal, precision: 12, scale: 2
    change_column :spree_bids, :amount, :decimal, precision: 12, scale: 2
  end
end
