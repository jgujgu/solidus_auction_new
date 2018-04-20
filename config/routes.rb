Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :auctions
    resources :bids
    resource :auction_settings, only: ['show', 'update', 'edit']
  end
  resources :auctions, only: %i{index show}
  resources :votes, only: %i{index}
  get 'vote_up', to: "auctions#vote_up"
  get 'vote_down', to: "auctions#vote_down"
  get 'vote_count', to: "auctions#vote_count"
  get 'starting_soon', to: "auctions#starting_soon"
  get 'ending_soon', to: "auctions#ending_soon"
  get 'recently_completed', to: "auctions#recently_completed"

  resources :bids, only: %i{index new create}
end
