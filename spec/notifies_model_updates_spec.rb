RSpec.describe ModelTransporter::NotifiesModelUpdates do
  it 'exists' do
    expect(described_class).not_to be nil
  end

  it 'enqueues model updates' do
    expect(ModelTransporter::BatchModelUpdates).to receive(:enqueue_model_updates)

    user = User.create(username: 'andrew')

    blog_post = BlogPost.create(
      author: user,
      title: 'Hello, world!'
    )

    expect(blog_post.id).not_to be nil
  end
end
