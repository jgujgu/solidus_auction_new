class Spree::Admin::AuctionsController < Spree::Admin::ResourceController
  create.before :create_before
  helper_method :disable_on_start
  helper_method :disable_on_complete
  helper Spree::Helpers::LocalTimeHelper

  def index
    session[:return_to] = request.url
    @collection = @collection.current_end_datetime_descending
    respond_with(@collection)
  end

  def show
    redirect_to action: :edit
  end

  private

  def disable_on_start(auction_started, enabled_options)
    if auction_started
      { readonly: true, disabled: true }.merge(enabled_options)
    else
      enabled_options
    end
  end

  def disable_on_complete(auction_complete, enabled_options)
    if auction_complete
      { readonly: true, disabled: true }.merge(enabled_options)
    else
      enabled_options
    end
  end

  def create_before
    @auction.creator = spree_current_user if spree_user_signed_in?
  end

  def permitted_auction_attributes
    %i{id title description starting_datetime planned_end_datetime starting_price reserve_price bid_increment time_increment countdown product_id checkout_time_minutes}
  end

  def permitted_resource_params
    params.require(:auction).permit(permitted_auction_attributes)
  end
end
