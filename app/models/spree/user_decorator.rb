Spree::User.class_eval do
  has_many :bids, class_name: 'Spree::Bid', foreign_key: "bidder_id"
  has_many :auctions, class_name: 'Spree::Auction', through: :bids
  acts_as_voter
end
