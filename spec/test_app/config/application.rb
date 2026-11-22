require "active_record/railtie"
require "action_controller/railtie"
require "action_cable/engine"

require "model_transporter"

module TestApp
  class Application < Rails::Application
    # Use the defaults of whichever Rails version the suite is running against,
    # so each CI job exercises that version's real behaviour.
    config.load_defaults Rails::VERSION::STRING.to_f

    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.secret_key_base = "model_transporter_test_app"
    config.logger = Logger.new(nil)
    config.active_support.deprecation = :stderr
    config.action_controller.allow_forgery_protection = false
  end
end
