RSpec.describe ModelTransporter::BatchModelUpdates, 'edge cases' do
  let(:user) { User.create!(username: 'Andrew') }

  it 'accepts a proc as the actor' do
    expect(ActionCable.server).to receive(:broadcast).with('key', hash_including(actor_id: user.id))

    described_class.with_transporter_actor(-> { user }) do
      described_class.enqueue_model_updates('key', {})
    end
  end

  it 'sends a nil actor_id when the actor proc returns nil' do
    expect(ActionCable.server).to receive(:broadcast).with('key', hash_including(actor_id: nil))

    described_class.with_transporter_actor(-> { nil }) do
      described_class.enqueue_model_updates('key', {})
    end
  end

  it 'clears the actor after the block' do
    described_class.with_transporter_actor(user) { }

    expect(ActionCable.server).to receive(:broadcast).with('key', hash_including(actor_id: nil))
    described_class.enqueue_model_updates('key', {})
  end

  it 'flushes queued updates and stops batching when the block raises' do
    expect(ActionCable.server).to receive(:broadcast).once.ordered.with(AdminChannel.broadcasting_for('tags'), anything)

    expect {
      described_class.batch_model_updates do
        Tag.create!(name: 'before error')
        raise 'boom'
      end
    }.to raise_error('boom')

    # No longer batching: the next update is pushed immediately.
    expect(ActionCable.server).to receive(:broadcast).once.ordered.with('key', anything)
    described_class.enqueue_model_updates('key', {})
  end

  it 'merges updates to the same record within a batch' do
    expect(ActionCable.server).to receive(:broadcast).once { |_, message|
      expect(message[:payload][:creates]['tags'].keys).to eq(['first'])
      expect(message[:payload][:deletes]['tags'].keys).to eq(['first'])
    }

    described_class.batch_model_updates do
      Tag.create!(name: 'first').destroy!
    end
  end
end
