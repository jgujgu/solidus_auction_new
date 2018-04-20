Spree::Admin::ResourceController.class_eval do
  around_action :set_time_zone, if: :spree_current_user

  private

  def set_time_zone(&block)
    Time.use_zone(spree_current_user.time_zone, &block)
  end
end
