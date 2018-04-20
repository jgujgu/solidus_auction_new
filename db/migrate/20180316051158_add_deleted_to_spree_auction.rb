class AddDeletedToSpreeAuction < ActiveRecord::Migration[5.1]
  def change
    add_column :spree_auctions, :deleted, :boolean
  end
end
