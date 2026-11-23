require "active_record/railtie"
require "action_controller/railtie"
require "action_cable/engine"

require "model_transporter"

module TestApp
  class Application < Rails::Application
    config.load_defaults 8.1

    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.secret_key_base = "model_transporter_test_app"
    config.logger = Logger.new(nil)
    config.active_support.deprecation = :stderr
    config.action_controller.allow_forgery_protection = false
  end
end
