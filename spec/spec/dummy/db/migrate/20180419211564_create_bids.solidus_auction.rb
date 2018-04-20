# This migration comes from solidus_auction (originally 20180225235226)
class CreateBids < ActiveRecord::Migration[5.1]
  def change
    create_table :spree_bids do |t|
      t.integer :auction_id
      t.integer :bidder_id
      t.integer :amount
      t.boolean :visible, default: false
      t.boolean :accepted, default: false

      t.timestamps
    end
  end
end
