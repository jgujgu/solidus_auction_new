FactoryBot.define do
  factory :auction, class: Spree::Auction do
    title "My First Auction"
    description "My First Description"
    starting_price 25.00
    bid_increment 1.00
    starting_datetime Time.now
    planned_end_datetime Time.now + 1.day

    product
    association :creator, factory: :user
  end

  factory :bid, class: Spree::Bid do
    amount 26.00
    auction
    association :bidder, factory: :user
  end
end
