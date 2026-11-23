RSpec.describe ModelTransporter::NotifiesModelUpdates, 'options' do
  let(:channel) { AdminChannel.broadcasting_for('tags') }

  describe 'id_key:' do
    it 'keys created models by the configured attribute instead of id' do
      tag = Tag.new(name: 'urgent')

      expect(ModelTransporter::BatchModelUpdates).to receive(:enqueue_model_updates) { |broadcasting_key, payload|
        expect(broadcasting_key).to eq(channel)
        expect(payload[:creates]['tags'].keys).to eq(['urgent'])
        expect(payload[:creates]['tags']['urgent']).to eq(tag)
      }

      tag.save!
    end

    it 'keys deleted models by the configured attribute' do
      tag = Tag.create!(name: 'stale')

      expect(ModelTransporter::BatchModelUpdates).to receive(:enqueue_model_updates) { |_, payload|
        expect(payload[:deletes]).to eq('tags' => { 'stale' => {} })
      }

      tag.destroy!
    end
  end

  describe 'on:' do
    it 'only registers callbacks for the listed events' do
      tag = Tag.create!(name: 'quiet')

      expect(ModelTransporter::BatchModelUpdates).not_to receive(:enqueue_model_updates)

      tag.update!(color: 'red')
    end

    it 'still notifies on the listed events' do
      expect(ModelTransporter::BatchModelUpdates).to receive(:enqueue_model_updates).once

      Tag.create!(name: 'loud')
    end
  end

  it 'does not notify when the transaction is rolled back' do
    expect(ModelTransporter::BatchModelUpdates).not_to receive(:enqueue_model_updates)

    ActiveRecord::Base.transaction(requires_new: true) do
      Tag.create!(name: 'rolled back')
      raise ActiveRecord::Rollback
    end
  end
end
