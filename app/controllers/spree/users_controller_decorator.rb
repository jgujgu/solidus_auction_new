if !Rails.env.test?
  Spree::UsersController.class_eval do
    helper Spree::Helpers::LocalTimeHelper
  end
end
