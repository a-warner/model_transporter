module ModelTransporter::NotifiesModelUpdates
  extend ActiveSupport::Concern

  included do
    class_attribute :notifies_model_updates_options
    self.notifies_model_updates_options = {}
  end

  class_methods do
    def notifies_model_updates(channel:, on: %i(create update destroy))
      self.notifies_model_updates_options = { channel: channel }

      if on.include?(:create)
        after_create_commit -> { notify_model_updates(:creates, self) }
      end

      if on.include?(:update)
        after_update_commit -> { notify_model_updates(:updates, self) }
      end

      if on.include?(:destroy)
        after_destroy_commit -> { notify_model_updates(:deletes, {}) }
      end
    end
  end

  def notify_model_updates(update_type, model_state)
    channel = instance_exec(&(self.class.notifies_model_updates_options[:channel]))

    payload = { creates: {}, updates: {}, deletes: {} }
    payload[update_type] = { self.class.name.pluralize.underscore => { self.id => model_state } }

    ModelTransporter::BatchModelUpdates.enqueue_model_updates(
      channel,
      payload
    )
  end
end
