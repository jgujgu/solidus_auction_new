Deface::Override.new(
  virtual_path: 'spree/shared/_order_details',
  name: :order_item_description,
  replace: "[data-hook='order_item_description']",
  partial: 'spree/shared/order_item_description'
)
