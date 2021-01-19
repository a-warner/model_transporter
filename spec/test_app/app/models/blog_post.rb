class BlogPost < ApplicationRecord
  belongs_to :author, class_name: 'User'
  has_many :comments

  validates :title, presence: true

  notifies_model_updates channel: -> { AdminChannel.broadcasting_for('all') }
end
