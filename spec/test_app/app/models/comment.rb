class Comment < ApplicationRecord
  belongs_to :author, class_name: 'User'
  belongs_to :blog_post

  validates :body, presence: true

  notifies_model_updates channel: 'AdminChannel', channel_model: -> { 'all' }
end
