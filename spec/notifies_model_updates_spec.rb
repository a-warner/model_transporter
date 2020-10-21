RSpec.describe ModelTransporter::NotifiesModelUpdates do
  it 'exists' do
    expect(described_class).not_to be nil
  end

  it "doesn't enqueue model updates for unregistered models" do
    expect(ModelTransporter::BatchModelUpdates).not_to receive(:enqueue_model_updates)
    user = User.create(username: 'andrew')
  end

  it 'enqueues model updates on create' do
    user = User.create(username: 'andrew')

    blog_post = BlogPost.new(
      author: user,
      title: 'Hello, world!'
    )

    expect(ModelTransporter::BatchModelUpdates).to receive(:enqueue_model_updates) { |broadcasting_key, payload|
      expect(broadcasting_key).to eq AdminChannel.broadcasting_for('all')

      expect(payload[:creates]['blog_posts']).to match(hash_including(blog_post.id => blog_post))
    }

    blog_post.save

    expect(blog_post.id).not_to be nil
  end
end
