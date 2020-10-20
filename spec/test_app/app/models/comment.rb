class Comment < ApplicationRecord
  belongs_to :author, class_name: 'User'
  belongs_to :blog_post

  validates :body, presence: true
end
