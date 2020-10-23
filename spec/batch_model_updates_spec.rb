CommentsController = Class.new(ApplicationController)

RSpec.describe ModelTransporter::BatchModelUpdates do
  it 'pushes model updates' do
    broadcasting_key = 'broadcasting_key'
    message = { test: 'message' }

    expect(ActionCable.server).to receive(:broadcast).with(broadcasting_key, hash_including(payload: message))
    described_class.enqueue_model_updates(broadcasting_key, message)
  end

  describe 'request update batching', type: :controller do
    controller CommentsController do
      def create
        @blog_post = BlogPost.find(params[:blog_post_id])

        @comment = @blog_post.comments.create!(params.require(:comment).permit(:body, :author_id))

        render json: @comment
      end

      private

      def current_player # TODO: remove this / make configurable
        nil
      end
    end

    let(:user) { User.create(username: 'Andrew') }
    let(:comment_author) { User.create(username: 'John') }

    specify 'batches model updates' do
      blog_post = BlogPost.create!(
        author: user,
        title: 'Hello, world!'
      )

      expect(ActionCable.server).to receive(:broadcast).once

      post :create, params: {
        blog_post_id: blog_post.id,
        comment: {
          body: 'Hello, world!',
          author_id: comment_author.id
        }
      }

      expect(response.status).to eq(200)
    end
  end
end
