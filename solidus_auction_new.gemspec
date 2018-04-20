# encoding: UTF-8
$:.push File.expand_path('../lib', __FILE__)
require 'solidus_auction/version'

Gem::Specification.new do |s|
  s.name        = 'solidus_auction'
  s.version     = "0.0.6"
  s.summary     = 'Adds auction functionality to a Solidus store'
  s.description = 'Add auctions and bidding to a Solidus store - adds consumer frontend and admin pages'
  s.license     = 'BSD-3-Clause'
  s.required_ruby_version = ">= 2.1"

  s.author      = "Jeffrey Gu"
  s.homepage = "https://github.com/jgujgu/solidus_auction"

  s.files        = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- spec/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'acts_as_votable'
  s.add_dependency 'deface'
  s.add_dependency 'solidus', ['>= 1.1', '< 3']

  s.add_development_dependency 'awesome_print'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_bot_rails'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'rails-controller-testing'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
end
