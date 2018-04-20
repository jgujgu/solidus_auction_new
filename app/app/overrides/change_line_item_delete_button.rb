Deface::Override.new(
  virtual_path: 'spree/orders/_line_item',
  name: :line_item_delete,
  replace: "[data-hook='cart_item_delete']",
  partial: 'spree/shared/line_item_delete'
)
