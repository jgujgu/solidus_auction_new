require 'spec_helper'

RSpec.describe Spree::Bid, type: :model do
  context 'initializes' do
    let(:bidder) { create(:user) }
    let(:bid) { create(:bid, { bidder: bidder }) }

    it 'has an amount' do
      expect(bid.amount).to eq 26.00
    end

    it 'has a bidder' do
      expect(bid.bidder).to be bidder
    end

    it 'has no visibility or acceptance by default' do
      expect(bid.visible).to be false
      expect(bid.accepted).to be false
    end
  end

  context 'changes state during auction reception' do
    let(:creator) { create(:user) }
    let(:product) { create(:product) }
    let!(:auction) {
      create(:auction, {
      product: product,
      creator: creator,
      starting_price: 25.00,
      bid_increment: 1.00
    })}
    let(:bidder) { create(:user) }
    let(:bidder1) { create(:user) }
    let(:bidder2) { create(:user) }

    it 'is visible and accepted as the highest bid within increment' do
      bid = create(:bid, amount: 26.00, auction: auction, bidder: bidder)

      auction.receive_bid(bid)
      expect(auction.current_price).to eq 26.00
      bid.reload
      expect(bid.visible).to be true
      expect(bid.accepted).to be true
    end

    it 'is invisible and unaccepted if it is below current price' do
      bid = create(:bid, amount: 15.00, auction: auction, bidder: bidder)

      auction.receive_bid(bid)
      expect(auction.current_price).to eq 25.00
      bid.reload
      expect(bid.visible).to be false
      expect(bid.accepted).to be false
    end

    it 'is invisible and accepted as the highest bid exceeding increment' do
      bid = create(:bid, amount: 50.00, auction: auction, bidder: bidder)

      auction.receive_bid(bid)
      expect(auction.current_price).to eq 26.00
      bid.reload
      expect(bid.visible).to be false
      expect(bid.accepted).to be true
    end

    it 'is visible and accepted even when out-autobid' do
      bid1 = create(:bid, amount: 50.00, auction: auction, bidder: bidder1)

      auction.receive_bid(bid1)
      expect(auction.current_price).to eq 26.00

      bid2 = create(:bid, amount: 30.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)
      expect(auction.current_price).to eq 31.00

      bid2.reload
      expect(bid2.visible).to be true
      expect(bid2.accepted).to be true
    end
  end
end
