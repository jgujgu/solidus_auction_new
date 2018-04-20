class Spree::Bid < Spree::Base
  belongs_to :auction, class_name: 'Spree::Auction'
  belongs_to :bidder, class_name: 'Spree::User'

  validates :auction_id, presence: true
  validates :bidder_id, presence: true
  validates :amount, presence: true

  extend Spree::DisplayMoney
  money_methods :amount

  scope :accepted, -> { where(accepted: true) }
  scope :visible, -> { where(visible: true) }
  scope :delinquent, -> { where(delinquent: true) }
  scope :not_delinquent, -> { where(delinquent: false) }

  def is_autobid?
    !visible && accepted
  end

  def bidder_display_name
    bidder.email
  end
end
