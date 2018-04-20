class Spree::Auction < Spree::Base
  belongs_to :product, class_name: 'Spree::Product'
  belongs_to :creator, class_name: 'Spree::User'
  belongs_to :variant, class_name: 'Spree::Variant'
  belongs_to :highest_bidder, class_name: 'Spree::User'
  has_many :bids, class_name: 'Spree::Bid'

  before_save :init_current_price, if: :new_record?
  before_save :set_current_end_datetime
  after_find :set_complete
  after_find :check_for_deadline

  validates :title, presence: true
  validates :description, presence: true
  validates :starting_datetime, presence: true, in_future: true, if: :new_record?
  validates :planned_end_datetime, presence: true, in_future: true, if: :new_record?
  validates :product_id, presence: true
  validates :creator_id, presence: true
  validates :starting_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :reserve_price, numericality: { greater_than_or_equal_to: 0 }
  validates :bid_increment, numericality: { greater_than_or_equal_to: 0 }
  validates :time_increment, numericality: { greater_than_or_equal_to: 0 }
  validates :countdown, numericality: { greater_than_or_equal_to: 0 }

  scope :current_end_datetime_descending, -> { order("current_end_datetime DESC") }
  scope :current_end_datetime_ascending, -> { order(:current_end_datetime) }
  scope :starting_datetime_descending, -> { order("starting_datetime DESC") }
  scope :starting_datetime_ascending, -> { order("starting_datetime") }
  scope :in_progress, -> { where("starting_datetime <= ?", Time.now) }
  scope :incomplete, -> { where(complete: false) }
  scope :complete, -> { where(complete: true) }

  config = Spree::AuctionSettings::Config

  scope :starting_soon, -> { where(starting_datetime: Time.now..(Time.now + config.starting_soon_hours.hours)) }
  scope :ending_soon, -> { where(current_end_datetime: Time.now..(Time.now + config.ending_soon_hours.hours)) }
  scope :recently_completed, -> { where(current_end_datetime: (Time.now - config.recently_completed_hours.hours)..Time.now).complete }

  acts_as_votable

  def init_current_price
    self.current_price = starting_price
  end

  def set_current_end_datetime
    if planned_end_datetime != planned_end_datetime_was
      self.current_end_datetime = planned_end_datetime
    end
  end

  def reserve_met?
    current_price >= reserve_price
  end

  def order_complete?
    if order
      order.complete?
    end
  end

  def won?
    true if complete && reserve_met? && highest_bidder
  end

  def started?
    if starting_datetime
      Time.now >= starting_datetime
    end
  end

  def order
    if variant
      variant.orders.first
    end
  end

  def in_progress?
    started? && !complete
  end

  def visible_bids
    bids.visible
  end

  def checkout_deadline
    current_end_datetime + checkout_time_minutes.minutes
  end

  def checkout_deadline_not_met?
    Time.now > checkout_deadline
  end

  def visible_bids_in_chron_order
    visible_bids.order("updated_at DESC")
  end

  def visible_bids_in_id_order
    visible_bids.order("id")
  end

  def current_end_datetime_as_float
    current_end_datetime.to_f * 1000
  end

  def checkout_deadline_as_float
    checkout_deadline.to_f * 1000
  end

  def starting_datetime_as_float
    starting_datetime.to_f * 1000
  end

  def accepted_bids
    bids.accepted
  end

  def accepted_bids_in_order
    accepted_bids.order("amount DESC")
  end

  def accepted_not_delinquent_bids_in_order
    accepted_bids.not_delinquent.order("amount DESC")
  end

  def highest_bid
    accepted_bids_in_order.first
  end

  def highest_bidder_bids
    highest_bidder.bids.where(auction_id: id)
  end

  def second_highest_bid
    accepted_bids_in_order.second
  end

  def top_bids_tied
    if second_highest_bid
      highest_bid.amount == second_highest_bid.amount
    end
  end

  def ending_soon?
    current_end_datetime - Time.now <= 1.hour
  end

  def in_countdown?
    current_end_datetime - Time.now <= countdown.seconds
  end

  extend Spree::DisplayMoney
  money_methods :reserve_price, :current_price, :starting_price, :bid_increment

  def reserve_price_as_usd
    as_usd reserve_price
  end

  def current_price_as_usd
    as_usd current_price
  end

  def as_usd(price_in_dollars)
    Money.new(price_in_dollars)
  end

  def deleted?
    deleted
  end

  def set_complete
    if !complete && current_end_datetime <= Time.now
      self.complete = true
      save
      if won?
        add_winning_item_to_highest_bidder_cart
      end
    end
  end

  def check_for_deadline
    if won? && checkout_deadline_not_met? && !order_complete?
      highest_bidder_bids.update_all(delinquent: true)
      highest_bidder_order = highest_bidder.last_incomplete_spree_order
      if highest_bidder_order
        highest_bidder_order.contents.remove(variant, 1)
      end

      bid = accepted_not_delinquent_bids_in_order.first
      if bid
        self.highest_bidder = bid.bidder
        self.current_price = bid.amount
        self.current_end_datetime = checkout_deadline
        save
        add_winning_item_to_highest_bidder_cart
      else
        self.highest_bidder_id = nil
        save
      end
    end
  end

  def add_winning_item_to_highest_bidder_cart
    user = highest_bidder
    cart = get_user_cart(user)
    new_variant = product.variants.create(price: current_price, track_inventory: false)
    cart.contents.add(new_variant)
    self.variant = new_variant
    save
  end

  def get_user_cart(user)
    last_user_order = user.last_incomplete_spree_order

    if last_user_order
      last_user_order
    else
      user.orders.create
    end
  end

  def set_current_price_and_highest_bidder(price, id)
    self.current_price = price
    self.highest_bidder_id = id
  end

  def receive_bid(bid)
    bid_amount = bid.amount
    current_price_with_increment = current_price + bid_increment
    bid_undercuts_current_price = bid_amount < current_price_with_increment
    if complete
      bid = nil
      message = Spree.t("auction_is_complete")
    elsif bid_undercuts_current_price
      bid = nil
      message = Spree.t("bid_not_high_enough")
    else
      max_bid = highest_bid
      if max_bid
        max_bid_amount = max_bid.amount
        if max_bid.bidder_id == bid.bidder_id
          if bid_amount > max_bid_amount
            if reserve_met? && top_bids_tied
              amount = current_price_with_increment
              new_bid = bids.create(bidder_id: max_bid.bidder_id, amount: amount, visible: true, accepted: true)
              bid.update(visible: false, accepted: true)
              message = "#{Spree.t(:autobid_up_to)} #{bid.display_amount}. #{Spree.t(:you_successfully_bid)} #{new_bid.display_amount}."
              set_current_price_and_highest_bidder(amount, bid.bidder_id)
            elsif !reserve_met? && bid_amount >= reserve_price
              amount = reserve_price
              set_current_price_and_highest_bidder(amount, max_bid.bidder_id)
              new_bid = bids.create(bidder_id: max_bid.bidder_id, amount: amount, visible: true, accepted: true)
              bid.update(visible: false, accepted: true)
              message = "#{Spree.t(:autobid_up_to)} #{bid.display_amount}. #{Spree.t(:you_successfully_bid)} #{new_bid.display_amount}. #{Spree.t(:met_reserve_price)}."
            elsif !reserve_met? && bid_amount < reserve_price
              bid.update(visible: false, accepted: true)
              message = "#{Spree.t(:autobid_up_to)} #{bid.display_amount}."
            elsif reserve_met? && bid_amount > current_price_with_increment && max_bid.is_autobid?
              bid.update(visible: false, accepted: true)
              max_bid.update(visible: false, accepted: true)
              message = "#{Spree.t(:autobid_up_to)} #{bid.display_amount}."
            elsif reserve_met? && bid_amount > current_price_with_increment && !max_bid.is_autobid?
              bid.update(visible: false, accepted: true)
              message = "#{Spree.t(:autobid_up_to)} #{bid.display_amount}."
            else
              amount = bid_amount
              max_bid.update(visible: false, accepted: false)
              bid.update(visible: false, accepted: true)
              set_current_price_and_highest_bidder(amount, bid.bidder_id)
              message = "#{Spree.t(:autobid_up_to)} #{bid.display_amount}."
            end
          else
            bid = nil
            message = Spree.t(:less_than_original_autobid)
          end
        else
          max_bid_is_higher = max_bid_amount > bid_amount
          max_bid_is_lower = max_bid_amount < bid_amount
          max_bid_with_increment = max_bid.amount + bid_increment
          if max_bid_is_higher
            bid_amount_with_increment = bid_amount + bid_increment
            if bid_amount_with_increment > max_bid_amount
              amount = max_bid_amount
            else
              amount = bid_amount_with_increment
            end
            bid.update(visible: true, accepted: true)
            bids.create(bidder_id: max_bid.bidder_id, amount: amount, visible: true, accepted: true)
            set_current_price_and_highest_bidder(amount, max_bid.bidder_id)
            bid = nil
            message = Spree.t(:you_were_outbid)
          elsif max_bid_is_lower
            if !reserve_met? && bid_amount >= reserve_price
              amount = reserve_price
            elsif max_bid_with_increment > bid_amount
              amount = bid_amount
            else
              amount = max_bid_with_increment
            end

            max_bid.update(visible: true, accepted: true)
            if max_bid_with_increment == bid_amount
              bid.update(visible: true, accepted: true)
              message = "#{Spree.t(:you_successfully_bid)} #{bid.display_amount}."
            else
              new_bid = bids.create(bidder_id: bid.bidder_id, amount: amount, visible: true, accepted: true)
              bid.update(visible: false, accepted: true)
              message = "#{Spree.t(:autobid_up_to)} #{bid.display_amount}. #{Spree.t(:you_successfully_bid)} #{new_bid.display_amount}."
            end
            set_current_price_and_highest_bidder(amount, bid.bidder_id)
          else
            amount = max_bid.amount
            bid.update(visible: true, accepted: true)
            max_bid.update(visible: true, accepted: true)
            set_current_price_and_highest_bidder(amount, max_bid.bidder_id)
            bid = nil
            message = Spree.t(:there_was_a_tie_autobid_wins)
          end
        end
      elsif bid_amount > current_price_with_increment
        if !reserve_met? && bid_amount >= reserve_price
          amount = reserve_price
        else
          amount = current_price_with_increment
        end
        set_current_price_and_highest_bidder(amount, bid.bidder_id)
        bid.update(visible: false, accepted: true)
        new_bid = bids.create(bidder_id: bid.bidder_id, amount: amount, visible: true, accepted: true)
        message = "#{Spree.t(:autobid_up_to)} #{bid.display_amount}. #{Spree.t(:you_successfully_bid)} #{new_bid.display_amount}."
      else
        bid.update(visible: true, accepted: true)
        amount = current_price_with_increment
        set_current_price_and_highest_bidder(amount, bid.bidder_id)
        message = "#{Spree.t(:you_successfully_bid)} #{bid.display_amount}."
      end
      if in_countdown?
        self.current_end_datetime += time_increment.seconds
      end
      save
    end
    [bid, message]
  end
end
