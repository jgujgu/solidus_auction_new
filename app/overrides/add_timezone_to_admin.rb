if Spree::Backend::Config.respond_to?(:menu_items)
  Deface::Override.new(
    virtual_path: 'spree/admin/users/_form',
    name: :users,
    insert_bottom: "[data-hook='admin_user_form_roles']",
    partial: 'spree/admin/shared/time_zone_field'
  )
end
