class CreateCollections < ActiveRecord::Migration[6.0]
  def change
    create_table :collections do |t|
      t.string :name, null: false
      t.integer :blog_posts_count, null: false, default: 0

      t.timestamps null: false
    end

    change_table :blog_posts do |t|
      t.belongs_to :collection
    end
  end
end
