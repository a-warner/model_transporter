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
    new_blog_post.save!

    new_blog_post.update!(title: 'test')
    new_blog_post.destroy
  end

  describe 'when model updates are configured' do
    before(:all) do
      BlogPost.class_eval do
        notifies_model_updates channel: 'AdminChannel', channel_model: -> { 'all' }
      end
    end

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
  end
end
