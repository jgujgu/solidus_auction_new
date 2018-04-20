Spree::Product.class_eval do
  has_many :auctions, class_name: 'Spree::Auction'
end
