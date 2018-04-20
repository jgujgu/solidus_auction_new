class Spree::BidsController < Spree::StoreController
  def index
    @auction = Spree::Auction.find(params[:auction_id])
    @bids = @auction.visible_bids_in_chron_order
  end

  def new
    @auction = Spree::Auction.find(params[:auction_id])
    if spree_current_user
      @bid = Spree::Bid.new(auction: @auction)
    else
      flash[:error] = Spree.t("must_be_signed_in_to_bid")
      redirect_to auction_path @auction
    end
  end

  def create
    @auction = Spree::Auction.find(params[:auction_id])
    if spree_current_user
      @bid = Spree::Bid.create(auction: @auction, bidder: spree_current_user, amount: params[:amount])
      @recorded_bid, message = @auction.receive_bid(@bid)
      if @recorded_bid
        flash[:success] = message
      else
        flash[:error] = message
      end
    else
      flash[:error] = Spree.t("must_be_signed_in_to_bid")
    end
    redirect_to auction_path @auction
  end

  private

  def flash_message_for(object, event_sym)
    resource_desc  = object.class.model_name.human
    resource_desc += " \"#{object.name}\"" if object.respond_to?(:name) && object.name.present?
    t(event_sym, resource: resource_desc, scope: 'spree')
  end

  def permitted_bid_attributes
    %i{auction_id amount}
  end

  def bid_params
    params.require(:bid).permit(permitted_bid_attributes)
  end
end
