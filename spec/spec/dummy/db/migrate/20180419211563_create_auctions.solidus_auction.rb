# This migration comes from solidus_auction (originally 20180225234309)
class CreateAuctions < ActiveRecord::Migration[5.1]
  def change
    create_table :spree_auctions do |t|
      t.text :title
      t.text :description
      t.datetime :starting_datetime
      t.datetime :planned_end_datetime
      t.datetime :current_end_datetime
      t.integer :starting_price, default: 0
      t.integer :reserve_price, default: 0
      t.integer :current_price
      t.integer :bid_increment, default: 1
      t.integer :time_increment, default: 0
      t.integer :countdown, default: 0
      t.integer :product_id
      t.integer :creator_id
      t.integer :highest_bidder_id
      t.integer :auction_type_id
      t.integer :store_id
      t.boolean :complete, default: false

      t.timestamps
    end
  end
end
