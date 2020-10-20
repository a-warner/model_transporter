class User < ApplicationRecord
  has_many :blog_posts
  has_many :comments, as: :author

  validates :username, presence: true
end
