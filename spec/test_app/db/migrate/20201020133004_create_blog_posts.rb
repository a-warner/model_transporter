class CreateBlogPosts < ActiveRecord::Migration[6.0]
  def change
    create_table :blog_posts do |t|
      t.string :title, null: false
      t.text :body
      t.datetime :published_at
      t.belongs_to :author, null: false

      t.timestamps null: false
    end
  end
end
