# This migration comes from solidus_auction (originally 20180321203019)
class AddTimeZoneToSpreeUser < ActiveRecord::Migration[5.1]
  def change
    add_column :spree_users, :time_zone, :string, default: "UTC"
  end
end
