require 'spec_helper'

RSpec.describe Spree::BidsController, type: :controller do
  let(:auction) { create(:auction) }
  let(:product) { create(:product) }
  let(:bidder1) { create(:user) }
  let(:bidder2) { create(:user) }
  let(:bidder3) { create(:user) }

  context '#index' do
    it 'lists bids' do
      bids = [
        create(:bid, bidder: bidder1, amount: 26.00, auction: auction),
        create(:bid, bidder: bidder2, amount: 27.00, auction: auction),
        create(:bid, bidder: bidder3, amount: 28.00, auction: auction)
      ]

      bids.each do |b|
        auction.receive_bid(b)
      end
      auction.reload

      get :index, params: { auction_id: auction.id }
      expect(assigns[:bids]).to match_array bids
      expect(assigns[:auction]).to eq auction
    end

    it 'renders the index template' do
      get :index, params: { auction_id: auction.id }
      expect(response.status).to eq 200
      expect(response).to render_template :index
    end
  end

  context '#new' do
    before do
      controller.stub spree_current_user: bidder1
      controller.stub spree_user_signed_in?: true
    end

    it 'assigns a bid instance variable' do
      get :new, params: { auction_id: auction.id }
      expect(assigns[:bid]).to be_a_kind_of Spree::Bid
    end

    it 'redirects to auction page if not signed in' do
      controller.stub spree_current_user: nil
      controller.stub spree_user_signed_in?: false
      get :new, params: { auction_id: auction.id }
      expect(response.status).to eq 302
      expect(flash[:error]).to eq "You must be signed in to bid."
    end
  end

  context '#create' do
    before do
      controller.stub spree_current_user: bidder1
      controller.stub spree_user_signed_in?: true
    end

    it 'creates a normal bid' do
      bid_params = {
        auction_id: auction.id,
        amount: 26.00
      }

      expect {
        post :create, params: bid_params
      }.to change(Spree::Bid, :count).by(1)
    end

    it 'creates an autobid' do
      bid_params = {
        auction_id: auction.id,
        amount: 40.00
      }

      expect {
        post :create, params: bid_params
      }.to change(Spree::Bid, :count).by(2)
    end

    it 'fails if not signed in' do
      bid_params = {
        auction_id: auction.id,
        amount: Random.rand(4000)
      }
      controller.stub spree_current_user: nil
      controller.stub spree_user_signed_in?: false
      post :create, params: bid_params
      expect(flash[:error]).to eq "You must be signed in to bid."
    end

    it 'flashes a success' do
      bid_params = {
        auction_id: auction.id,
        amount: 26.00
      }

      post :create, params: bid_params
      expect(flash[:success]).to eq "You successfully bid $26.00."
    end

    it 'redirects to auction' do
      bid_params = {
        auction_id: auction.id,
        amount: 26.00
      }

      post :create, params: bid_params
      expect(response.status).to eq 302
    end
  end
end
