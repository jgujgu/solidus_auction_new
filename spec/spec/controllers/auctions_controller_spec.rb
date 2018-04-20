require 'spec_helper'

RSpec.describe Spree::AuctionsController, type: :controller do
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
    let!(:auction) { create(:auction) }

    context 'for an auction that does not exist' do
      it 'responds with a 404' do
        expect {
          get :show, params: { id: 'not_real' }
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    it 'assigns an auction instance variable' do
      get :show, params: { id: auction.id }
      expect(response.status).to eq 200
      expect(assigns[:auction]).to eq auction
    end

    it 'renders the show template' do
      get :show, params: { id: auction.id }
      expect(response.status).to eq 200
      expect(response).to render_template :show
    end
  end
end
