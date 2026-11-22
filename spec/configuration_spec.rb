RSpec.describe ModelTransporter::Configuration do
  describe 'railtie' do
    it 'adds notifies_model_updates to Active Record models' do
      expect(ActiveRecord::Base).to respond_to(:notifies_model_updates)
    end

    it 'batches updates in every controller' do
      expect(ActionController::Base.ancestors).to include(ModelTransporter::ControllerAdditions)
    end
  end

  describe 'push_adapter' do
    let(:adapter) do
      Class.new do
        attr_reader :pushes
        def initialize; @pushes = []; end
        def push_update(channel, message); @pushes << [channel, message]; end
      end.new
    end

    around do |example|
      previous_adapter = ModelTransporter.configuration.push_adapter
      ModelTransporter.configure { |config| config.push_adapter = adapter }
      example.run
    ensure
      ModelTransporter.configure { |config| config.push_adapter = previous_adapter }
    end

    it 'sends updates through a custom adapter instead of Action Cable' do
      expect(ActionCable.server).not_to receive(:broadcast)

      tag = Tag.create!(name: 'custom')

      expect(adapter.pushes.size).to eq(1)
      channel, message = adapter.pushes.first
      expect(channel).to eq(AdminChannel.broadcasting_for('tags'))
      expect(message).to include(type: 'server_event/MODEL_UPDATES', actor_id: nil)
      expect(message[:payload][:creates]['tags']).to eq('custom' => tag)
    end
  end
end
