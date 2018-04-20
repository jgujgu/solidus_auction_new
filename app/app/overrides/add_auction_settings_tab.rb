if Spree::Backend::Config.respond_to?(:menu_items)
  Deface::Override.new(
    virtual_path: 'spree/admin/shared/_settings_sub_menu',
    name: :auction_settings,
    insert_bottom: "[data-hook='admin_settings_sub_tabs']",
    partial: 'spree/admin/shared/auction_settings_button'
  )
end
