class Spree::VotesController < Spree::StoreController
  def index
    @auctions = spree_current_user.find_up_voted_items
  end
end
