CommentsController = Class.new(ApplicationController)

RSpec.describe ModelTransporter::BatchModelUpdates do
  let(:user) { User.create(username: 'Andrew') }

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

      protected

      def current_user
        @current_user
      end

      private

      def permitted_params
        params.require(:comment).permit(:body, :author_id)
      end
    end

    let(:comment_author) { User.create(username: 'John') }
    let!(:blog_post) do
      BlogPost.create!(
        author: user,
        title: 'Hello, world!'
      )
    end

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
end
