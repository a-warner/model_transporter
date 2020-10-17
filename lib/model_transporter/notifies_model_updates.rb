module ModelTransporter::NotifiesModelUpdates
  extend ActiveSupport::Concern

  included do
    class_attribute :notifies_model_updates_options
    self.notifies_model_updates_options = {}
  end

  class_methods do
    def notifies_model_updates(channel:, channel_model:, on: %i(create update destroy))
      self.notifies_model_updates_options = {
        channel: channel,
        channel_model: channel_model
      }

      if on.include?(:create)
        after_create_commit -> { notify_model_updates(:creates) }
      end

      if on.include?(:update)
        after_update_commit -> { notify_model_updates(:updates) }
      end

      if on.include?(:destroy)
        after_destroy_commit -> { notify_model_updates(:deletes) }
      end
    end
  end

  def notify_model_updates(update_type)
    channel = self.class.notifies_model_updates_options[:channel].constantize
    model = Array(instance_exec(&(self.class.notifies_model_updates_options[:channel_model])))

    payload = { creates: {}, updates: {}, deletes: {} }
    payload[update_type] = { self.class.name.pluralize.underscore => { self.id => self } }

    ModelTransporter::BatchModelUpdates.enqueue_model_updates(
      channel.broadcasting_for(model),
      payload
    )
  end
end
