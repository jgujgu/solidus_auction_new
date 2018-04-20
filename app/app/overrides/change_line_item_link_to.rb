Deface::Override.new(
  virtual_path: 'spree/orders/_line_item',
  name: :line_item_link_to,
  replace: "[data-hook='cart_item_description']",
  partial: 'spree/shared/line_item_link_to'
)
