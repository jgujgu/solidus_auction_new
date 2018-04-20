# This migration comes from solidus_auction (originally 20180316051158)
class AddDeletedToSpreeAuction < ActiveRecord::Migration[5.1]
  def change
    add_column :spree_auctions, :deleted, :boolean
  end
end
