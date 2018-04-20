Deface::Override.new(
  virtual_path: 'spree/admin/shared/_order_summary',
  name: :auction_links_to_order_info,
  insert_bottom: ".additional-info",
  partial: 'spree/admin/shared/auction_links_to_order_info'
)
