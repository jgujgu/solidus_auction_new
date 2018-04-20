Deface::Override.new(
  virtual_path: 'spree/users/show',
  name: :auctions_table_show,
  insert_after: "[data-hook='account_summary']",
  partial: 'spree/shared/auctions_table_show'
)
