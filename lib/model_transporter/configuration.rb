module ModelTransporter
  class Configuration
    attr_accessor :actor
    attr_accessor :push_adapter

    def initialize
      @push_adapter = PushAdapter::ActionCable.new
    end
  end
end
