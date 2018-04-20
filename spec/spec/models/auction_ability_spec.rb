require 'spec_helper'

require "cancan/matchers"

describe Spree::AuctionAbility do
  context 'permissions' do
    let(:admin_user) { create(:admin_user) }
    let(:admin_user2) { create(:admin_user) }
    let(:user) { create(:user) }
    let(:product) { create(:product) }
    let!(:auction) {
      create(:auction, {
        product: product,
        creator: admin_user
      })}

    it 'only allows admins to create an auction' do
       expect(Spree::AuctionAbility.new(admin_user)).to be_able_to(:create, Spree::Auction.new)
       expect(Spree::AuctionAbility.new(user)).to_not be_able_to(:create, Spree::Auction.new)
    end

    it 'only allows certain admins to edit an auction' do
       expect(Spree::AuctionAbility.new(admin_user)).to be_able_to(:edit, auction)
       expect(Spree::AuctionAbility.new(admin_user2)).to_not be_able_to(:edit, auction)
    end

    it 'only allows certain admins to update an auction' do
       expect(Spree::AuctionAbility.new(admin_user)).to be_able_to(:update, auction)
       expect(Spree::AuctionAbility.new(admin_user2)).to_not be_able_to(:update, auction)
    end

    it 'only allows certain admins to delete an auction' do
       expect(Spree::AuctionAbility.new(admin_user)).to be_able_to(:destroy, auction)
       expect(Spree::AuctionAbility.new(admin_user2)).to_not be_able_to(:destroy, auction)
    end
  end
end
