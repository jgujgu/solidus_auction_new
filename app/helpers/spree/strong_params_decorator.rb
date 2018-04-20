Spree::Core::ControllerHelpers::StrongParameters.class_eval do
  def permitted_user_attributes
    permitted_attributes.user_attributes + [
      bill_address_attributes: permitted_address_attributes,
      ship_address_attributes: permitted_address_attributes
    ] + %i{time_zone username}
  end
end
