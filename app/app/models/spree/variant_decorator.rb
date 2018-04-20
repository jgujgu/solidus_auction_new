Spree::Variant.class_eval do
  has_one :auction, class_name: 'Spree::Auction'
end
