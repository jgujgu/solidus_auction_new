# This migration comes from solidus_auction (originally 20180417180042)
class AddDelinquentToSpreeBids < ActiveRecord::Migration[5.1]
  def change
    add_column :spree_bids, :delinquent, :boolean, default: false
  end
end
