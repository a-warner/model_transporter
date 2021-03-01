module ModelTransporter
  module BatchModelUpdates
    extend self
    MODEL_UPDATES_EVENT = 'server_event/MODEL_UPDATES'
    REQUEST_STORE_NAMESPACE = 'MODEL_TRANSPORTER'

    def enqueue_model_updates(channel, message)
      if updates_being_batched?
        current_model_updates[channel] << message
      else
        cooked_message = base_model_update_message.merge(payload: message)
        push_update(channel, cooked_message)
      end
    end

    def with_transporter_actor(actor)
      RequestStore.store["#{REQUEST_STORE_NAMESPACE}.transporter_actor"] = actor
      yield
    ensure
      RequestStore.store.delete("#{REQUEST_STORE_NAMESPACE}.transporter_actor")
    end

    def batch_model_updates
      RequestStore.store["#{REQUEST_STORE_NAMESPACE}.model_updates"] = Hash.new { |h, k| h[k] = [] }

      yield
    ensure
      consolidate_model_updates.each do |channel, message|
        push_update(channel, message)
      end

      RequestStore.store.delete("#{REQUEST_STORE_NAMESPACE}.model_updates")
    end

    private

    def transporter_actor_id
      case actor = RequestStore.store["#{REQUEST_STORE_NAMESPACE}.transporter_actor"]
      when Proc
        actor.call&.id
      else
        actor&.id
      end
    end

    def consolidate_model_updates
      current_model_updates.each.with_object({}) do |(channel, messages), consolidated_messages|
        consolidated_messages[channel] = messages.each.with_object(base_model_update_message) do |message, consolidated_message|
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
      RequestStore.store["#{REQUEST_STORE_NAMESPACE}.model_updates"]
    end

    def updates_being_batched?
      !!current_model_updates
    end

    def push_update(channel, message)
      ModelTransporter.configuration.push_adapter.push_update(channel, message)
    end
  end
end
