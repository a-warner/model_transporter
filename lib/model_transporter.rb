require 'active_support/all'
require "model_transporter/version"
require "model_transporter/configuration"
require "model_transporter/notifies_model_updates"
require "model_transporter/batch_model_updates"
require "model_transporter/railtie"
require 'request_store'

module ModelTransporter
  class Error < StandardError; end

  mattr_accessor :configuration
  @@configuration = Configuration.new

  def self.configure
    yield configuration
  end
end
