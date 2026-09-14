# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "debug"
gem "herb"
# Released Rails versions are not compatible with JSON 3 yet.
# TODO: Upgrade to a Rails 8.1 release with JSON 3 support when available.
# Then move this constraint to the Gemfiles for Rails versions that still need it.
# https://github.com/rails/rails/pull/58601
gem "json", @json_gem_requirement || "< 3"
gem "puma"
if !@rails_gem_requirement
  gem "rails", ">= 7.2"
  ruby ">= 3.3.0"
else
  # causes Dependabot to ignore the next line and update the previous gem "rails"
  rails = "rails"
  gem rails, @rails_gem_requirement
end
gem "rubocop"
gem "rubocop-shopify"
gem "sprockets-rails"
gem "sqlite3"
gem "yard"

group :test do
  gem "capybara"
  gem "capybara-lockstep"
  if !@minitest_gem_requirement
    gem "minitest"
  else
    # causes Dependabot to ignore the next line and update the previous gem "minitest"
    minitest = "minitest"
    gem minitest, @minitest_gem_requirement
  end
  gem "mocha"
  gem "selenium-webdriver"
end
