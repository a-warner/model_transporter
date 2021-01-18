module ModelTransporter
  module ControllerAdditions
    extend ActiveSupport::Concern

    included do
      around_action :batch_model_updates
    end

    def batch_model_updates(&block)
      if ModelTransporter.configuration.actor
        actor = Proc.new do
          ModelTransporter.configuration.actor.to_proc.call(self)
        end
      end

      ModelTransporter::BatchModelUpdates.with_transporter_actor(actor) do
        ModelTransporter::BatchModelUpdates.batch_model_updates(&block)
      end
    end
  end
end
