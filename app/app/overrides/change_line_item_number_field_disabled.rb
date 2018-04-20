Deface::Override.new(
  virtual_path: 'spree/orders/_line_item',
  name: :line_item_disable,
  replace: "[data-hook='cart_item_quantity']",
  partial: 'spree/shared/line_item_number_field_disabled'
)
