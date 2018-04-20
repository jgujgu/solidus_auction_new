Deface::Override.new(
  virtual_path: 'spree/checkout/_delivery',
  name: :stock_item_name,
  replace: ".item-name",
  partial: 'spree/shared/stock_item_name'
)
