class Collection < ApplicationRecord
  has_many :blog_posts

  notifies_model_updates channel: -> { CollectionChannel.broadcasting_for(self) }
end
