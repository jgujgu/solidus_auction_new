class AddDelinquentToSpreeBids < ActiveRecord::Migration[5.1]
  def change
    add_column :spree_bids, :delinquent, :boolean, default: false
  end
end
