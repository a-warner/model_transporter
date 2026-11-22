# Exercises the non-default `id_key:` and `on:` options.
class Tag < ApplicationRecord
  notifies_model_updates channel: -> { AdminChannel.broadcasting_for('tags') },
    id_key: :name,
    on: %i(create destroy)
end
