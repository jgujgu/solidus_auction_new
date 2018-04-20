require 'spec_helper'

describe Spree::Admin::AuctionsController do
  stub_authorization!

  let(:auction) { create(:auction) }
  let(:product) { create(:product) }
  let(:admin_user) { create(:admin_user) }
  let(:user) { create(:user) }
  let(:auction_params) {
    { auction: {
      title: FFaker::Book.title,
      description: FFaker::Book.description,
      starting_datetime: Time.now,
      planned_end_datetime: Time.now + 1.day,
      starting_price: Random.rand(4000),
      product_id: product.id
    } }
  }

  before do
    controller.stub spree_current_user: admin_user
    controller.stub spree_user_signed_in?: true
  end

  context '#index' do
    it 'lists auctions' do
      auctions = [
        create(:auction),
        create(:auction),
        create(:auction)
      ]
      get :index
      expect(assigns[:auctions]).to match_array auctions
    end

    it 'renders the index template' do
      get :index
      expect(response.status).to eq 200
      expect(response).to render_template :index
    end
  end

  context '#show' do
    it 'redirects to #edit' do
      get :show, params: { id: auction.id }
      expect(response.status).to eq 302
    end
  end

  context '#new' do
    it 'assigns an auction instance variable' do
      get :new
      expect(assigns[:object]).to be_a_kind_of Spree::Auction
    end

    it 'assigns an auction instance variable' do
      get :new
      expect(assigns[:auction]).to be_a_kind_of Spree::Auction
    end

    it 'renders the new template' do
      get :new
      expect(response.status).to eq 200
      expect(response).to render_template :new
    end
  end

  context '#create' do
    it 'creates an auction' do
      expect {
        post :create, params: auction_params
      }.to change(Spree::Auction, :count).by(1)
    end

    it 'fails if the user is not authorized to create a review' do
      controller.stub spree_current_user: user
      controller.stub spree_user_signed_in?: true
      controller.stub(:authorize!) { raise }
      expect{
        post :create, params: auction_params
      }.to raise_error RuntimeError
    end

    it 'creates an auction connected to the signed in admin user' do
      post :create, params: auction_params
      expect(Spree::Auction.first.creator).to eq admin_user
    end

    it 'flashes a success' do
      post :create, params: auction_params
      expect(flash[:success]).to eq "Auction has been successfully created!"
    end

    it 'redirects to #show then #edit' do
      post :create, params: auction_params
      expect(response.status).to eq 302
    end
  end

  context '#edit' do
    it 'assigns an auction instance variable' do
      get :edit, params: { id: auction.id }
      expect(assigns[:auction]).to be_a_kind_of Spree::Auction
    end

    it 'renders the edit template' do
      get :edit, params: { id: auction.id }
      expect(response.status).to eq 200
      expect(response).to render_template :edit
    end
  end

  context '#update' do
    let(:auction) { create(:auction, creator: admin_user) }
    let(:update_auction_params) {
      { id: auction.id, auction: {
        title: FFaker::Book.title,
        description: FFaker::Book.description,
        starting_price: Random.rand(4000),
        time_increment: Random.rand(60),
        bid_increment: Random.rand(100),
        countdown: 600
      } }
    }

    it 'updates the auction' do
      put :update, params: update_auction_params
      auction.reload
      update_auction_params[:auction].each do |k, v|
        expect(auction[k]).to eq v
      end
    end

    it 'flashes a successfully updated notice' do
      put :update, params: update_auction_params
      expect(flash[:success]).to eq("Auction has been successfully updated!")
    end

    it 'flashes an unsuccessfully updated notice for a nonexisting id number' do
      update_auction_params[:id] = auction.id + 10
      put :update, params: update_auction_params
      expect(flash[:error]).to eq("Auction is not found")
    end
  end
end
