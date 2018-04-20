class AddDefaultToDatetimes < ActiveRecord::Migration[5.1]
  def change
    change_column_default :spree_auctions, :starting_datetime, -> { 'CURRENT_TIMESTAMP' }
    change_column_default :spree_auctions, :planned_end_datetime, -> { 'CURRENT_TIMESTAMP' }
    change_column_default :spree_auctions, :current_end_datetime, -> { 'CURRENT_TIMESTAMP' }
  end
end
