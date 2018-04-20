class Spree::AuctionAbility
  include CanCan::Ability

  def initialize(user)
    can :create, Spree::Auction do
      user.admin?
    end

    can %i{edit update destroy delete clone}, Spree::Auction do |auction|
      auction.creator_id == user.id
    end
  end
end
