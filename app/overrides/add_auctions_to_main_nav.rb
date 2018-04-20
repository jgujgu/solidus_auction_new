Deface::Override.new(
  virtual_path: 'spree/shared/_main_nav_bar',
  name: :auctions_menu_link,
  insert_after: "#home-link",
  partial: 'spree/shared/auctions_link'
)
