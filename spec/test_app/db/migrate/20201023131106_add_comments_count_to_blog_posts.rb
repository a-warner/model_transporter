class AddCommentsCountToBlogPosts < ActiveRecord::Migration[6.0]
  def change
    add_column :blog_posts, :comments_count, :integer, null: false, default: 0
  end
end
