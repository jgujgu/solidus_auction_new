class AddTimeZoneToSpreeUser < ActiveRecord::Migration[5.1]
  def change
    add_column :spree_users, :time_zone, :string, default: "UTC"
  end
end
