class Spree::AuctionsController < Spree::StoreController
  helper Spree::BaseHelper
  helper Spree::Helpers::LocalTimeHelper
  helper_method :config

  def index
    @auctions = Spree::Auction.in_progress.incomplete.current_end_datetime_ascending
  end

  def starting_soon
    @auctions = Spree::Auction.incomplete.starting_soon.starting_datetime_ascending
    render :index
  end

  def ending_soon
    @auctions = Spree::Auction.incomplete.ending_soon
    render :index
  end

  def recently_completed
    @auctions = Spree::Auction.recently_completed
    render :index
  end

  def show
    @auction = Spree::Auction.find(params[:id])
    @product = @auction.product
    @product_properties = @product.product_properties.includes(:property)
  end

  def vote_count
    auction = Spree::Auction.find_by(id: params[:auction_id])
    votes = auction.cached_votes_up
    render json: { votes: votes }
  end

  def vote_up
    auction = Spree::Auction.find_by(id: params[:auction_id])
    user = Spree::User.find_by(id: params[:user_id])
    auction.liked_by user
    votes = auction.cached_votes_up
    render json: { votes: votes, voted_for: 1 }
  end

  def vote_down
    auction = Spree::Auction.find_by(id: params[:auction_id])
    user = Spree::User.find_by(id: params[:user_id])
    auction.downvote_from user
    votes = auction.cached_votes_up
    render json: { votes: votes, voted_for: 0 }
  end
end
