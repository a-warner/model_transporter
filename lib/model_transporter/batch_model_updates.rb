module ModelTransporter::BatchModelUpdates
  extend ActiveSupport::Concern

  MODEL_UPDATES_EVENT = 'server_event/MODEL_UPDATES'

  included do
    around_action :batch_model_updates
  end

  def self.enqueue_model_updates(broadcasting_key, message)
    if updates_being_batched?
      current_model_updates[broadcasting_key] << message
    else
      cooked_message = base_model_update_message(actor_id: transporter_actor_id).merge(payload: message)
      ActionCable.server.broadcast(broadcasting_key, cooked_message)
    end
  end

  private

  def self.with_transporter_actor(actor)
    RequestStore.store[:transporter_actor_id] = actor&.id
    yield
  ensure
    RequestStore.store.delete(:transporter_actor_id)
  end

  def self.transporter_actor_id
    RequestStore.store[:transporter_actor_id]
  end

  def with_transporter_actor(actor, &block)
    ModelTransporter::BatchModelUpdates.with_transporter_actor(actor, &block)
  end

  def transporter_actor_id
    if ModelTransporter::BatchModelUpdates.transporter_actor_id
      ModelTransporter::BatchModelUpdates.transporter_actor_id
    elsif ModelTransporter.configuration.actor
      ModelTransporter.configuration.actor.to_proc.call(self)&.id
    end
  end

  def batch_model_updates
    RequestStore.store[:model_updates] = Hash.new { |h, k| h[k] = [] }

    yield
  ensure
    consolidate_model_updates.each do |broadcasting_key, message|
      ActionCable.server.broadcast(broadcasting_key, message)
    end
  end

  def consolidate_model_updates
    current_model_updates.each.with_object({}) do |(broadcasting_key, messages), consolidated_messages|
      consolidated_messages[broadcasting_key] = messages.each.with_object(base_model_update_message) do |message, consolidated_message|
        message.each do |update_type, updated_models|
          updated_models.each do |model_name, models|
            consolidated_message[:payload][update_type][model_name] ||= {}
            consolidated_message[:payload][update_type][model_name].merge!(models)
          end
        end
      end
    end
  end

  def self.base_model_update_message(actor_id:)
    {
      type: MODEL_UPDATES_EVENT,
      actor_id: actor_id,
      payload: { creates: {}, updates: {}, deletes: {} }
    }
  end

  def base_model_update_message
    ModelTransporter::BatchModelUpdates.base_model_update_message(actor_id: transporter_actor_id)
  end

  def self.current_model_updates
    RequestStore.store[:model_updates]
  end

  def current_model_updates
    ModelTransporter::BatchModelUpdates.current_model_updates
  end

  def self.updates_being_batched?
    !!current_model_updates
  end
end
