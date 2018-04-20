Deface::Override.new(
  virtual_path: 'spree/admin/stock_items/_stock_management',
  name: :variant_stock_item_disable,
  replace: "[class='variant-stock-items']",
  partial: 'spree/shared/variant_stock_item_disable'
)
