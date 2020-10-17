module ModelTransporter
  class Railtie < Rails::Railtie
    initializer "model_transporter.batch_model_updates.setup" do |app|
      ActiveSupport.on_load(:action_controller) do
        ActionController::Base.send(:include, BatchModelUpdates)
      end
    end

    initializer "model_transporter.notifies_model_updates.setup" do |app|
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.send(:include, NotifiesModelUpdates)
      end
    end
  end
end
