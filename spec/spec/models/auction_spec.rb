require 'spec_helper'

RSpec.describe Spree::Auction, type: :model do
  context 'initializes' do
    let(:bidder) { create(:user) }
    let!(:auction) { create(:auction) }

    it 'has a title' do
      expect(auction.title).to eq "My First Auction"
    end

    it 'has a product' do
      auction.reload
      id = auction.product.id
      expect(auction.product).to eq Spree::Product.find(id)
    end

    it 'has a creator' do
      auction.reload
      id = auction.creator.id
      expect(auction.creator).to eq Spree::User.find(id)
    end

    it 'has a starting price' do
      expect(auction.starting_price).to eq 25.00
    end

    it 'has a bid increment' do
      expect(auction.bid_increment).to eq 1.00
    end

    it 'has a starting datetime' do
      expect(auction.starting_datetime).to be_a_kind_of ActiveSupport::TimeWithZone
    end

    it 'has a planned end datetime' do
      expect(auction.planned_end_datetime).to be_a_kind_of ActiveSupport::TimeWithZone
    end

    it 'has not completed' do
      expect(auction.complete).to be false
    end

    it 'has inits the current_price as the starting_price' do
      expect(auction.current_price).to eq 25.00
    end

    it 'has a default checkout deadline 1 day (1440 minutes) ahead' do
      checkout_deadline = auction.checkout_deadline
      expect(checkout_deadline).to eq(auction.current_end_datetime + 1440.minutes)
    end
  end

  context 'processes bids' do
    let!(:auction) {
      create(:auction, {
        starting_price: 25.00,
        bid_increment: 1.00
      })}
    let(:bidder1) { create(:user) }
    let(:bidder2) { create(:user) }
    let(:bidder3) { create(:user) }
    let(:bidder4) { create(:user) }

    it 'updates current price when bid amount is higher than current price' do
      bid = create(:bid, amount: 26.00, auction: auction)
      auction.receive_bid(bid)
      auction.reload
      expect(auction.visible_bids.count).to eq 1
      expect(auction.current_price).to eq 26.00
    end

    it 'does not update current price when bid amount is lower than current price' do
      bid = create(:bid, amount: 15.00, auction: auction)
      auction.receive_bid(bid)
      auction.reload
      expect(auction.visible_bids.count).to eq 0
      expect(auction.current_price).to eq 25.00
    end

    it 'does not update current price when bid amount the same as current price' do
      bid = create(:bid, amount: 25.00, auction: auction)
      auction.receive_bid(bid)
      auction.reload
      expect(auction.visible_bids.count).to eq 0
      expect(auction.current_price).to eq 25.00
    end

    it 'does not update current price when bid amount is lower than current price + increment' do
      bid = create(:bid, amount: 25.50, auction: auction)
      auction.receive_bid(bid)
      auction.reload
      expect(auction.visible_bids.count).to eq 0
      expect(auction.current_price).to eq 25.00
    end

    it 'updates current price to last price plus bid increment' do
      bid = create(:bid, amount: 27.00, auction: auction)
      auction.receive_bid(bid)
      auction.reload
      expect(auction.visible_bids.count).to eq 1
      expect(auction.current_price).to eq 26.00
    end

    it 'returns a bid for a successfully calculated bid' do
      bid = create(:bid, amount: 26.00, auction: auction)
      result, _ = auction.receive_bid(bid)
      expect(result).to be bid
    end

    it 'returns nil for a low bid' do
      bid = create(:bid, amount: 15.00, auction: auction)
      result, _ = auction.receive_bid(bid)
      expect(result).to be_falsey
    end

    it 'knows the highest bidder' do
      bid1 = create(:bid, amount: 26.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.highest_bidder).to eq bidder1
    end

    it 'handles bids from the same bidder with reserve' do
      auction = create(:auction, {
        starting_price: 25.00,
        reserve_price: 30.00,
        bid_increment: 1.00
      })
      bid1 = create(:bid, amount: 26.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.highest_bid).to eq bid1
      expect(auction.current_price).to eq 26.00
      expect(auction.bids.count).to eq 1
      expect(auction.visible_bids.count).to eq 1

      bid2 = create(:bid, amount: 35.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.current_price).to eq 30.00
      expect(auction.highest_bid).to eq bid2
      expect(auction.bids.count).to eq 3
      expect(auction.visible_bids.count).to eq 2
    end

    it 'handles bids from the same bidder without reserve' do
      auction = create(:auction, {
        starting_price: 25.00,
        bid_increment: 1.00
      })
      bid1 = create(:bid, amount: 26.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.highest_bid).to eq bid1
      expect(auction.current_price).to eq 26.00
      expect(auction.bids.count).to eq 1
      expect(auction.visible_bids.count).to eq 1

      bid2 = create(:bid, amount: 35.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.current_price).to eq 26.00
      expect(auction.highest_bid).to eq bid2
      expect(auction.bids.count).to eq 2
      expect(auction.visible_bids.count).to eq 1
    end

    it 'handles bids from the same bidder when undercutting reserve' do
      auction = create(:auction, {
        starting_price: 20.00,
        reserve_price: 40.00,
        bid_increment: 5.00
      })
      bid1 = create(:bid, amount: 25.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.highest_bid).to eq bid1
      expect(auction.current_price).to eq 25.00
      expect(auction.visible_bids.count).to eq 1

      bid2 = create(:bid, amount: 35.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.current_price).to eq 25.00
      expect(auction.highest_bid).to eq bid2
      expect(auction.visible_bids.count).to eq 1
    end

    it 'knows if reserve has been met' do
      auction = create(:auction, {
        starting_price: 25.00,
        reserve_price: 28.00,
        bid_increment: 1.00
      })
      bid1 = create(:bid, amount: 27.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.current_price).to eq 26.00
      expect(auction.reserve_met?).to be false

      bid2 = create(:bid, amount: 28.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.current_price).to eq 28.00
      expect(auction.reserve_met?).to be true
    end

    it 'autobids for a high bid' do
      bid1 = create(:bid, amount: 50.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.current_price).to eq 26.00
      expect(auction.visible_bids.count).to eq 1

      bid2 = create(:bid, amount: 28.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.current_price).to eq 29.00
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.visible_bids.count).to eq 3

      bid3 = create(:bid, amount: 30.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid3)
      auction.reload
      expect(auction.current_price).to eq 31.00
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.visible_bids.count).to eq 5

      bid4 = create(:bid, amount: 35.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid4)
      auction.reload
      expect(auction.current_price).to eq 36.00
      expect(auction.visible_bids.count).to eq 7
      expect(auction.highest_bidder).to eq bidder1
    end

    it 'shows the last autobid if outbidding it' do
      bid1 = create(:bid, amount: 50.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.current_price).to eq 26.00
      expect(auction.visible_bids.count).to eq 1

      bid2 = create(:bid, amount: 60.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.current_price).to eq 51.00
      expect(auction.highest_bidder).to eq bidder2
      expect(auction.visible_bids.count).to eq 3
      expect(auction.visible_bids_in_id_order[0].amount).to eq 50.00

      bid3 = create(:bid, amount: 80.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid3)
      auction.reload
      expect(auction.current_price).to eq 61.00
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.visible_bids.count).to eq 5
      expect(auction.visible_bids_in_id_order[-3].amount).to eq 60.00
    end

    it 'correctly autobids after an autobid tie' do
      bid1 = create(:bid, amount: 50.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.current_price).to eq 26.00
      expect(auction.visible_bids.count).to eq 1

      bid2 = create(:bid, amount: 50.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.current_price).to eq 50.00
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.visible_bids.count).to eq 3

      bid3 = create(:bid, amount: 80.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid3)
      auction.reload
      expect(auction.current_price).to eq 51.00
      expect(auction.highest_bidder).to eq bidder2
      expect(auction.visible_bids.count).to eq 4
    end

    it 'autobids for a high bid even when it changes' do
      bid1 = create(:bid, amount: 50.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.current_price).to eq 26.00
      expect(auction.visible_bids.count).to eq 1

      bid1 = create(:bid, amount: 80.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.current_price).to eq 26.00
      expect(auction.visible_bids.count).to eq 1

      bid2 = create(:bid, amount: 28.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.current_price).to eq 29.00
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.visible_bids.count).to eq 3

      bid3 = create(:bid, amount: 30.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid3)
      auction.reload
      expect(auction.current_price).to eq 31.00
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.visible_bids.count).to eq 5

      bid4 = create(:bid, amount: 35.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid4)
      auction.reload
      expect(auction.current_price).to eq 36.00
      expect(auction.visible_bids.count).to eq 7
      expect(auction.highest_bidder).to eq bidder1

      bid4 = create(:bid, amount: 75.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid4)
      auction.reload
      expect(auction.current_price).to eq 76.00
      expect(auction.visible_bids.count).to eq 9
      expect(auction.highest_bidder).to eq bidder1

      bid5 = create(:bid, amount: 90.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid5)
      auction.reload
      expect(auction.current_price).to eq 81.00
      expect(auction.visible_bids.count).to eq 11
      expect(auction.highest_bidder).to eq bidder2
    end

    it 'autobids to the highest autobid amount even if it does not meet bid increment' do
      bid1 = create(:bid, amount: 50.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.visible_bids.count).to eq 1
      expect(auction.current_price).to eq 26.00

      bid2 = create(:bid, amount: 49.50, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.current_price).to eq 50.00
      expect(auction.visible_bids.count).to eq 3
      expect(auction.highest_bidder).to eq bidder1
    end

    it 'autobids above the highest invisible bid' do
      bid1 = create(:bid, amount: 50.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.current_price).to eq 26.00

      bid2 = create(:bid, amount: 55.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.current_price).to eq 51.00
      expect(auction.visible_bids.count).to eq 3
      expect(auction.highest_bidder).to eq bidder2
    end

    it 'autobids above the highest invisible bid but not exceeding bidders amount' do
      bid1 = create(:bid, amount: 50.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.visible_bids.count).to eq 1
      expect(auction.current_price).to eq 26.00

      bid2 = create(:bid, amount: 50.50, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.current_price).to eq 50.50
      expect(auction.visible_bids.count).to eq 3
      expect(auction.highest_bidder).to eq bidder2
    end

    it 'favors the initial bidder in the event of an autobid tie' do
      bid1 = create(:bid, amount: 50.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.current_price).to eq 26.00
      expect(auction.highest_bidder).to eq bidder1

      bid2 = create(:bid, amount: 50.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.current_price).to eq 50.00
      expect(auction.visible_bids.count).to eq 3
      expect(auction.highest_bidder).to eq bidder1
    end

    it 'sets highest autobid amount to reserve price if there is one' do
      auction = create(:auction, {
        starting_price: 25.00,
        reserve_price: 30.00,
        bid_increment: 1.00
      })

      bid1 = create(:bid, amount: 50.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.current_price).to eq 30.00
      expect(auction.visible_bids.count).to eq 1
      expect(auction.reserve_met?).to be true
    end

    it 'jumps to reserve price if later autobids are higher' do
      auction = create(:auction, {
        starting_price: 25.00,
        reserve_price: 35.00,
        bid_increment: 1.00
      })

      bid1 = create(:bid, amount: 30.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.current_price).to eq 26.00
      expect(auction.visible_bids.count).to eq 1
      expect(auction.reserve_met?).to be false
      expect(auction.highest_bidder).to eq bidder1

      bid2 = create(:bid, amount: 31.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.current_price).to eq 31.00
      expect(auction.visible_bids.count).to eq 3
      expect(auction.reserve_met?).to be false
      expect(auction.highest_bidder).to eq bidder2

      bid3 = create(:bid, amount: 40.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid3)
      auction.reload
      expect(auction.current_price).to eq 35.00
      expect(auction.visible_bids.count).to eq 4
      expect(auction.reserve_met?).to be true
      expect(auction.highest_bidder).to eq bidder1
    end

    it 'creates new bids for each autobid' do
      bid1 = create(:bid, amount: 50.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.bids.count).to eq 2
      expect(auction.visible_bids.count).to eq 1

      bid2 = create(:bid, amount: 28.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.bids.count).to eq 4
      expect(auction.visible_bids.count).to eq 3
    end

    it 'manages a series of simple bids in the correct manner' do
      bid1 = create(:bid, amount: 26.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.current_price).to eq 26.00
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.bids.count).to eq 1
      expect(auction.visible_bids.count).to eq 1

      bid2 = create(:bid, amount: 27.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.current_price).to eq 27.00
      expect(auction.highest_bidder).to eq bidder2
      expect(auction.bids.count).to eq 2
      expect(auction.visible_bids.count).to eq 2

      bid3 = create(:bid, amount: 28.00, auction: auction, bidder: bidder3)
      auction.receive_bid(bid3)
      auction.reload
      expect(auction.current_price).to eq 28.00
      expect(auction.highest_bidder).to eq bidder3
      expect(auction.bids.count).to eq 3
      expect(auction.visible_bids.count).to eq 3
    end

    it 'manages a series of bids in the correct manner' do
      bid1 = create(:bid, amount: 27.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.current_price).to eq 26.00
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.bids.count).to eq 2
      expect(auction.visible_bids.count).to eq 1

      bid2 = create(:bid, amount: 30.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.current_price).to eq 28.00
      expect(auction.highest_bidder).to eq bidder2
      expect(auction.bids.count).to eq 4
      expect(auction.visible_bids.count).to eq 3

      bid3 = create(:bid, amount: 35.00, auction: auction, bidder: bidder3)
      auction.receive_bid(bid3)
      auction.reload
      expect(auction.current_price).to eq 31.00
      expect(auction.highest_bidder).to eq bidder3
      expect(auction.bids.count).to eq 6
      expect(auction.visible_bids.count).to eq 5

      bid4 = create(:bid, amount: 35.00, auction: auction, bidder: bidder4)
      auction.receive_bid(bid4)
      auction.reload
      expect(auction.current_price).to eq 35.00
      expect(auction.highest_bidder).to eq bidder3
      expect(auction.bids.count).to eq 7
      expect(auction.visible_bids.count).to eq 7

      bid5 = create(:bid, amount: 36.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid5)
      auction.reload
      expect(auction.current_price).to eq 36.00
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.bids.count).to eq 8
      expect(auction.visible_bids.count).to eq 8
    end

    it 'returns an ordered list of visible bids' do
      bid1 = create(:bid, amount: 50.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)

      bid2 = create(:bid, amount: 29.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)

      bid3 = create(:bid, amount: 31.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid3)

      expect(auction.visible_bids_in_chron_order.count).to eq 5
    end

    it 'does not autobid above a bidders own autobids' do
      bid1 = create(:bid, amount: 50.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)
      auction.reload
      expect(auction.current_price).to eq 26.00
      expect(auction.highest_bid).to eq bid1
      expect(auction.visible_bids.count).to eq 1

      bid2 = create(:bid, amount: 28.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid2)
      auction.reload
      expect(auction.current_price).to eq 26.00
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.highest_bid).to eq bid1
      expect(auction.visible_bids.count).to eq 1

      bid3 = create(:bid, amount: 30.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid3)
      auction.reload
      expect(auction.current_price).to eq 26.00
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.highest_bid).to eq bid1
      expect(auction.visible_bids.count).to eq 1

      bid4 = create(:bid, amount: 55.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid4)
      auction.reload
      expect(auction.current_price).to eq 26.00
      expect(auction.highest_bidder).to eq bidder1
      expect(auction.highest_bid).to eq bid4
      expect(auction.visible_bids.count).to eq 1
    end
  end

  context 'handles time' do
    let(:starting_datetime) { Time.now }
    let(:planned_end_datetime) { Time.now + 10.days + 5.minutes }
    let(:bidder) { create(:user) }
    let(:bidder1) { create(:user) }
    let(:bidder2) { create(:user) }
    let(:bidder3) { create(:user) }
    let!(:auction) {
      create(:auction, {
        starting_datetime: starting_datetime,
        planned_end_datetime: planned_end_datetime,
        time_increment: 60,
        highest_bidder: bidder,
        reserve_price: 30,
        countdown: 300
      })}

    it 'has the same planned and current end datetime in the default case' do
      starting_datetime = Time.now
      planned_end_datetime = Time.now + 1.minute

      auction = create(:auction, {
        starting_datetime: starting_datetime,
        planned_end_datetime: planned_end_datetime
      })

      expect(auction.planned_end_datetime).to eq auction.current_end_datetime
    end

    it 'knows if it has started' do
      starting_datetime = Time.now

      auction = create(:auction, {
        starting_datetime: starting_datetime
      })

      expect(auction.started?).to be true
    end

    it 'knows it is ending soon' do
      starting_datetime = Time.now
      planned_end_datetime = Time.now + 59.minutes

      auction = create(:auction, {
        starting_datetime: starting_datetime,
        planned_end_datetime: planned_end_datetime
      })

      expect(auction.ending_soon?).to be true
    end

    it 'knows it is not ending soon' do
      starting_datetime = Time.now
      planned_end_datetime = Time.now + 1.hour + 5.minutes

      auction = create(:auction, {
        starting_datetime: starting_datetime,
        planned_end_datetime: planned_end_datetime
      })

      expect(auction.ending_soon?).to be false
    end

    it 'does not have a countdown by default' do
      starting_datetime = Time.now
      planned_end_datetime = Time.now + 59.seconds
      auction = create(:auction, {
        starting_datetime: starting_datetime,
        planned_end_datetime: planned_end_datetime
      })

      expect(auction.in_countdown?).to be false
    end

    it 'knows it is in countdown mode' do
      starting_datetime = Time.now
      planned_end_datetime = Time.now + 59.seconds
      one_minute_countdown = 60
      auction = create(:auction, {
        starting_datetime: starting_datetime,
        planned_end_datetime: planned_end_datetime,
        countdown: one_minute_countdown
      })

      expect(auction.in_countdown?).to be true
    end

    it 'knows when it is complete' do
      starting_datetime = Time.now
      planned_end_datetime = Time.now + 1.seconds
      auction = create(:auction, {
        starting_datetime: starting_datetime,
        planned_end_datetime: planned_end_datetime,
        highest_bidder: bidder
      })
      sleep 2
      auction.reload
      expect(auction.complete).to be true
    end

    it 'adds the item to the winning bidders cart' do
      bid = create(:bid, amount: 30.00, auction: auction, bidder: bidder)
      auction.receive_bid(bid)
      auction.update(current_end_datetime: Time.now - 1.second)
      auction.reload
      expect(bidder.last_incomplete_spree_order.line_items.count).to eq 1
      expect(bidder.last_incomplete_spree_order.line_items.last.price).to eq 30.00
      expect(bidder.last_incomplete_spree_order.line_items.last.variant).to eq auction.variant
    end

    it 'does not add the item to the winning bidders cart if reserve not met' do
      bid = create(:bid, amount: 26.00, auction: auction, bidder: bidder)
      auction.receive_bid(bid)
      auction.update(current_end_datetime: Time.now - 1.second)
      auction.reload
      expect(auction.reserve_met?).to be false
      expect(bidder.last_incomplete_spree_order).to be nil
    end

    it 'awards the auction to the next highest bidder if not paid within checkout deadline' do
      starting_datetime = Time.now
      planned_end_datetime = Time.now + 5.minutes
      auction = create(:auction, {
        starting_datetime: starting_datetime,
        planned_end_datetime: planned_end_datetime
      })
      bid1 = create(:bid, amount: 27.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)

      bid2 = create(:bid, amount: 30.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)

      bid3 = create(:bid, amount: 35.00, auction: auction, bidder: bidder3)
      auction.receive_bid(bid3)

      current_end_datetime = Time.now
      auction.update(current_end_datetime: current_end_datetime)
      auction.reload

      expect(bidder3.last_incomplete_spree_order.line_items.count).to eq 1
      expect(bidder3.last_incomplete_spree_order.line_items.last.price).to eq 31.00
      expect(bidder3.last_incomplete_spree_order.line_items.last.variant).to eq auction.variant

      current_end_datetime = Time.now - (1.day + 5.minutes)
      auction.update(current_end_datetime: current_end_datetime)
      auction.reload

      expect(bidder3.last_incomplete_spree_order.line_items.empty?).to be true
      expect(bidder2.last_incomplete_spree_order.line_items.last.price).to eq 30.00
      expect(bidder2.last_incomplete_spree_order.line_items.last.variant).to eq auction.variant

      current_end_datetime = Time.now - (1.day + 5.minutes)
      auction.update(current_end_datetime: current_end_datetime)
      auction.reload

      expect(bidder2.last_incomplete_spree_order.line_items.empty?).to be true
      expect(bidder1.last_incomplete_spree_order.line_items.last.price).to eq 27.00
      expect(bidder1.last_incomplete_spree_order.line_items.last.variant).to eq auction.variant
    end

    it 'awards the auction to nobody if not paid within checkout deadline' do
      starting_datetime = Time.now
      planned_end_datetime = Time.now + 5.minutes
      auction = create(:auction, {
        starting_datetime: starting_datetime,
        planned_end_datetime: planned_end_datetime
      })
      bid1 = create(:bid, amount: 27.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)

      current_end_datetime = Time.now
      auction.update(current_end_datetime: current_end_datetime)
      auction.reload

      expect(bidder1.last_incomplete_spree_order.line_items.count).to eq 1
      expect(bidder1.last_incomplete_spree_order.line_items.last.price).to eq 26.00
      expect(bidder1.last_incomplete_spree_order.line_items.last.variant).to eq auction.variant

      current_end_datetime = Time.now - (1.day + 5.minutes)
      auction.update(current_end_datetime: current_end_datetime)
      auction.reload

      expect(bidder1.last_incomplete_spree_order.line_items.empty?).to be true
      expect(auction.won?).to be_falsey
    end

    it 'awards the auction to the highest bidder paid within checkout deadline' do
      starting_datetime = Time.now
      planned_end_datetime = Time.now + 5.minutes
      store = create(:store)
      auction = create(:auction, {
        starting_datetime: starting_datetime,
        planned_end_datetime: planned_end_datetime
      })
      bid1 = create(:bid, amount: 27.00, auction: auction, bidder: bidder1)
      auction.receive_bid(bid1)

      bid2 = create(:bid, amount: 30.00, auction: auction, bidder: bidder2)
      auction.receive_bid(bid2)

      bid3 = create(:bid, amount: 35.00, auction: auction, bidder: bidder3)
      auction.receive_bid(bid3)

      current_end_datetime = Time.now
      auction.update(current_end_datetime: current_end_datetime)
      auction.reload

      expect(bidder3.last_incomplete_spree_order.line_items.count).to eq 1
      expect(bidder3.last_incomplete_spree_order.line_items.last.price).to eq 31.00
      expect(bidder3.last_incomplete_spree_order.line_items.last.variant).to eq auction.variant

      order = bidder3.last_incomplete_spree_order
      order.update(store: store, state: "complete")
      expect(auction.order_complete?).to be true

      current_end_datetime = Time.now - (1.day + 5.minutes)
      auction.update(current_end_datetime: current_end_datetime)

      expect(auction.highest_bidder).to eq bidder3
      expect(auction.current_price).to eq 31.00
      expect(auction.won?).to be true
    end

    it 'does not allow any more bidding once complete' do
      starting_datetime = Time.now
      planned_end_datetime = Time.now + 1.seconds
      auction = create(:auction, {
        starting_datetime: starting_datetime,
        planned_end_datetime: planned_end_datetime,
        highest_bidder: bidder
      })
      sleep 2
      auction.reload
      bid = create(:bid, amount: 26.00, auction: auction)
      bid_result, _ = auction.receive_bid(bid)

      expect(bid_result).to be_falsey
      expect(bid.accepted).to be false
    end

    it 'increases current endtime with more bids inside a countdown' do
      starting_datetime = Time.now
      planned_end_datetime = Time.now + 59.seconds
      time_increment = 60
      one_minute_countdown = 60
      auction = create(:auction, {
        starting_price: 25.00,
        starting_datetime: starting_datetime,
        planned_end_datetime: planned_end_datetime,
        time_increment: time_increment,
        countdown: one_minute_countdown
      })

      bid1 = create(:bid, amount: 26.00, auction: auction)
      auction.receive_bid(bid1)
      auction.reload
      auction_end_difference = (auction.current_end_datetime - auction.planned_end_datetime).seconds
      expect(auction_end_difference).to be >= 59.seconds
    end
  end
end
