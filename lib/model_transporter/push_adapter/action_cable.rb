module ModelTransporter
  module PushAdapter
    class ActionCable
      def push_update(channel, message)
        ::ActionCable.server.broadcast(channel, message)
      end
    end
  end
end
