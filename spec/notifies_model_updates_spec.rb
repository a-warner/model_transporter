RSpec.describe ModelTransporter::NotifiesModelUpdates do
  let(:user) { User.create(username: 'Andrew') }

  let(:new_blog_post) do
    BlogPost.new(
      author: user,
      title: 'Hello, world!'
    )
  end

  let(:saved_blog_post) { new_blog_post.tap(&:save!) }

  it 'exists' do
    expect(described_class).not_to be nil
  end

  it "doesn't enqueue model updates for unregistered models" do
    expect(ModelTransporter::BatchModelUpdates).not_to receive(:enqueue_model_updates)
    test_user = User.create!(username: 'New user')
    test_user.update!(username: 'New user 2')
    test_user.destroy
  end

  describe 'when model updates are configured' do
    it 'enqueues model updates on create' do
      expect(ModelTransporter::BatchModelUpdates).to receive(:enqueue_model_updates) { |broadcasting_key, payload|
        expect(broadcasting_key).to eq AdminChannel.broadcasting_for('all')

        expect(payload[:updates]).to eq({})
        expect(payload[:deletes]).to eq({})

        expect(payload[:creates]['blog_posts']).to match(
          hash_including(new_blog_post.id => new_blog_post)
        )
      }

      new_blog_post.save!

      expect(new_blog_post.id).not_to be nil
    end

    it 'enqueues model updates on update' do
      blog_post = saved_blog_post

      expect(ModelTransporter::BatchModelUpdates).to receive(:enqueue_model_updates) { |broadcasting_key, payload|
        expect(broadcasting_key).to eq AdminChannel.broadcasting_for('all')

        expect(payload[:creates]).to eq({})
        expect(payload[:deletes]).to eq({})

        expect(payload[:updates]['blog_posts']).to match(
          hash_including(blog_post.id => having_attributes(title: 'Updated title'))
        )
      }

      blog_post.update!(title: 'Updated title')
    end

    it 'enqueues model updates on delete' do
      blog_post = saved_blog_post

      expect(ModelTransporter::BatchModelUpdates).to receive(:enqueue_model_updates) { |broadcasting_key, payload|
        expect(broadcasting_key).to eq AdminChannel.broadcasting_for('all')

        expect(payload[:creates]).to eq({})
        expect(payload[:updates]).to eq({})

        expect(payload[:deletes]['blog_posts']).to match(
          hash_including(blog_post.id => blog_post)
        )
      }

      blog_post.destroy!
    end

    it 'enqueues multiple updates' do
      blog_post = saved_blog_post
      expect(ModelTransporter::BatchModelUpdates).to receive(:enqueue_model_updates).twice

      saved_blog_post.update!(title: 'First update')
      saved_blog_post.update!(title: 'Second update')
    end
  end
end
