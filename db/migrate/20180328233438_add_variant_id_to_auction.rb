class AddVariantIdToAuction < ActiveRecord::Migration[5.1]
  def change
    add_column :spree_auctions, :variant_id, :integer
  end
end
