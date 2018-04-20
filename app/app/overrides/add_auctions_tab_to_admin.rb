if Spree::Backend::Config.respond_to?(:menu_items)
  Deface::Override.new(
    virtual_path: 'spree/admin/shared/_menu',
    name: :auctions,
    insert_top: "[data-hook='admin_tabs']",
    partial: 'spree/admin/shared/auctions_tab'
  )
end
