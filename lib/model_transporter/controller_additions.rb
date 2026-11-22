module ModelTransporter
  module ControllerAdditions
    extend ActiveSupport::Concern

    included do
      around_action :batch_model_updates
    end

    def batch_model_updates(&block)
      if (actor_config = ModelTransporter.configuration.actor)
        controller = self
        actor = Proc.new do
          if actor_config.respond_to?(:call)
            actor_config.call(controller)
          else
            # `send` rather than `to_proc`, so non-public helpers such as a
            # protected `current_user` work (Symbol#to_proc could call
            # protected methods on Ruby 3.0, but not on Ruby 3.2+).
            controller.send(actor_config)
          end
        end
      end

      ModelTransporter::BatchModelUpdates.with_transporter_actor(actor) do
        ModelTransporter::BatchModelUpdates.batch_model_updates(&block)
      end
    end
  end
end
