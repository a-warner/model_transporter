RSpec.describe ModelTransporter::BatchModelUpdates do
  it 'pushes model updates' do
    broadcasting_key = 'broadcasting_key'
    message = { test: 'message' }

    expect(ActionCable.server).to receive(:broadcast).with(broadcasting_key, hash_including(payload: message))
    described_class.enqueue_model_updates(broadcasting_key, message)
  end
end
