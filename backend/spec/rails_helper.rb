# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
# Force RAILS_ENV=test for the spec run. ||= would leave the inherited
# value alone, and docker-compose sets RAILS_ENV=development on the
# backend container — which previously caused rspec to run against the
# dev DB and trip uniqueness validations on seeded rows.
ENV['RAILS_ENV'] = 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.use_transactional_fixtures = true

  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
