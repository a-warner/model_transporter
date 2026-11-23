ENV["RAILS_ENV"] = "test"

require "bundler/setup"
require "model_transporter"

require File.expand_path("test_app/config/environment", __dir__)

require "rspec/rails"

# Build a fresh test database from the schema on every run, so the suite works
# from a clean checkout without any manual db setup.
FileUtils.mkdir_p(Rails.root.join("tmp"))
ActiveRecord::Schema.verbose = false
load Rails.root.join("db", "schema.rb")

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.use_transactional_fixtures = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
