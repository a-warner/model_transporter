module ModelTransporter::BatchModelUpdates
  extend ActiveSupport::Concern

  MODEL_UPDATES_EVENT = 'server_event/MODEL_UPDATES'

  included do
    around_action :batch_model_updates
  end

  def self.enqueue_model_updates(broadcasting_key, message)
    if outside_of_request_context?
      cooked_message = base_model_update_message(acting_player_id: nil).merge(payload: message)
      ActionCable.server.broadcast(broadcasting_key, cooked_message)
    else
      current_model_updates[broadcasting_key] << message
    end
  end

  private

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

  def self.base_model_update_message(acting_player_id:)
    {
      type: MODEL_UPDATES_EVENT,
      acting_player_id: acting_player_id,
      payload: { creates: {}, updates: {}, deletes: {} }
    }
  end

  def base_model_update_message
    ModelTransporter::BatchModelUpdates.base_model_update_message(acting_player_id: current_player&.id)
  end

  def self.current_model_updates
    RequestStore.store[:model_updates]
  end

  def current_model_updates
    ModelTransporter::BatchModelUpdates.current_model_updates
  end

  def self.outside_of_request_context?
    current_model_updates.nil?
  end
end

