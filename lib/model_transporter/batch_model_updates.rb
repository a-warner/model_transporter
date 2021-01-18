module ModelTransporter::BatchModelUpdates
  extend self
  MODEL_UPDATES_EVENT = 'server_event/MODEL_UPDATES'

  def enqueue_model_updates(broadcasting_key, message)
    if updates_being_batched?
      current_model_updates[broadcasting_key] << message
    else
      cooked_message = base_model_update_message.merge(payload: message)
      ActionCable.server.broadcast(broadcasting_key, cooked_message)
    end
  end

  def with_transporter_actor(actor)
    RequestStore.store[:transporter_actor] = actor
    yield
  ensure
    RequestStore.store.delete(:transporter_actor)
  end

  def batch_model_updates
    RequestStore.store[:model_updates] = Hash.new { |h, k| h[k] = [] }

    yield
  ensure
    consolidate_model_updates.each do |broadcasting_key, message|
      ActionCable.server.broadcast(broadcasting_key, message)
    end
  end

  private

  def transporter_actor_id
    case actor = RequestStore.store[:transporter_actor]
    when Proc
      actor.call&.id
    else
      actor&.id
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

  def base_model_update_message
    {
      type: MODEL_UPDATES_EVENT,
      actor_id: transporter_actor_id,
      payload: { creates: {}, updates: {}, deletes: {} }
    }
  end

  def current_model_updates
    RequestStore.store[:model_updates]
  end

  def updates_being_batched?
    !!current_model_updates
  end
end
