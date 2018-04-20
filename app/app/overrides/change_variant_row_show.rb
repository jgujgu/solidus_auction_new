Deface::Override.new(
  virtual_path: 'spree/admin/variants/_table',
  name: :variant_disable,
  replace: "[data-hook='variants_row']",
  partial: 'spree/shared/variant_row_disable'
)
