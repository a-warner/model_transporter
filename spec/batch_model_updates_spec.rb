CommentsController = Class.new(ApplicationController)
BlogPostsController = Class.new(ApplicationController)

RSpec.describe ModelTransporter::BatchModelUpdates do
  let!(:user) { User.create(username: 'Andrew') }

  let!(:blog_post) do
    BlogPost.create!(
      author: user,
      title: 'Hello, world!'
    )
  end

  it 'pushes model updates' do
    broadcasting_key = 'broadcasting_key'
    message = { test: 'message' }

    expect(ActionCable.server).to receive(:broadcast).with(broadcasting_key, hash_including(payload: message))
    described_class.enqueue_model_updates(broadcasting_key, message)
  end

  it 'tracks update actor' do
    broadcasting_key = 'broadcasting_key'
    message = { test: 'message' }

    expect(ActionCable.server).to receive(:broadcast).with(broadcasting_key, hash_including(actor_id: user.id))

    described_class.with_transporter_actor(user) do
      described_class.enqueue_model_updates(broadcasting_key, message)
    end
  end

  describe 'request update batching', type: :controller do
    controller CommentsController do
      def create
        @blog_post = BlogPost.find(params[:blog_post_id])
        @current_user = User.find(permitted_params[:author_id])

        @comment = @blog_post.comments.create!(permitted_params)
        @blog_post.update!(comments_count: @blog_post.comments.count)

        render json: @comment
      end

      def add_to_collection
        @blog_post = BlogPost.find(params[:blog_post_id])
        @collection = Collection.find(params[:collection_id])

        @blog_post.update!(collection: @collection)
        @collection.update!(blog_posts_count: @collection.blog_posts.count)
      end

      protected

      def current_user
        @current_user
      end

      private

      def permitted_params
        params.require(:comment).permit(:body, :author_id)
      end
    end

    let!(:comment_author) { User.create(username: 'John') }

    specify 'batches model updates' do
      expect(ActionCable.server).to receive(:broadcast).once { |broadcasting_key, message|
        expect(broadcasting_key).to eq AdminChannel.broadcasting_for('all')
        payload = message[:payload]

        expect(payload[:updates]['blog_posts']).to match(
          hash_including(blog_post.id => blog_post)
        )

        expect(payload[:creates]['comments'].values).to match(
          array_including(having_attributes(body: 'Hello, comment!'))
        )

        expect(message[:actor_id]).to be_nil
      }

      post :create, params: {
        blog_post_id: blog_post.id,
        comment: {
          body: 'Hello, comment!',
          author_id: comment_author.id
        }
      }

      expect(response.status).to eq(200)
    end

    context 'tracked actor' do
      around do |example|
        begin
          previous_actor = ModelTransporter.configuration.actor
          ModelTransporter.configure { |config| config.actor = :current_user }
          example.run
        ensure
          ModelTransporter.configure { |config| config.actor = previous_actor }
        end
      end

      specify 'sends actor id' do
        expect(ActionCable.server).to receive(:broadcast).once { |broadcasting_key, message|
          expect(message[:actor_id]).to eq(comment_author.id)
        }

        post :create, params: {
          blog_post_id: blog_post.id,
          comment: {
            body: 'Hello, comment!',
            author_id: comment_author.id
          }
        }
      end
    end
  end

  describe 'request update batching separate channels', type: :controller do
    controller BlogPostsController do
      def add_to_collection
        @blog_post = BlogPost.find(params[:blog_post_id])
        @collection = Collection.find(params[:collection_id])

        @blog_post.update!(collection: @collection)
        @collection.update!(blog_posts_count: @collection.blog_posts.count)

        render json: @blog_post
      end
    end

    specify 'sends messages on different channels' do
      routes.draw { post "add_to_collection" => "blog_posts#add_to_collection" }
      collection = Collection.create!(name: 'Test collection')

      expect(ActionCable.server).to receive(:broadcast).
        with(AdminChannel.broadcasting_for('all'), anything)

      expect(ActionCable.server).to receive(:broadcast).
        with(CollectionChannel.broadcasting_for(collection), anything)

      post :add_to_collection, params: {
        blog_post_id: blog_post.id,
        collection_id: collection
      }
    end
  end

  describe 'manually batches updates' do
    specify 'sends one push for multiple updates' do
      expect(ActionCable.server).to receive(:broadcast).once

      ModelTransporter::BatchModelUpdates.batch_model_updates do
        post = BlogPost.create!(
          author: user,
          title: 'Test post'
        )

        Comment.create!(
          author: user,
          blog_post: post,
          body: 'commenting on my own post'
        )
      end
    end

    specify 'sends a fresh message each time' do
      post = nil

      ModelTransporter::BatchModelUpdates.batch_model_updates do
        post = BlogPost.create!(
          author: user,
          title: 'Test post'
        )

        Comment.create!(
          author: user,
          blog_post: post,
          body: 'commenting on my own post'
        )
      end

      expect(ActionCable.server).to receive(:broadcast).once { |broadcasting_key, message|
        expect(broadcasting_key).to eq AdminChannel.broadcasting_for('all')
        payload = message[:payload]

        expect(payload[:creates]['blog_posts']).to be_blank

        expect(payload[:creates]['comments'].values.size).to eq(1)
      }

      ModelTransporter::BatchModelUpdates.batch_model_updates do
        Comment.create!(
          author: user,
          blog_post: post,
          body: 'commenting on my own post again'
        )
      end
    end
  end
end
