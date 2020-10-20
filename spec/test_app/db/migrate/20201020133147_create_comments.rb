class CreateComments < ActiveRecord::Migration[6.0]
  def change
    create_table :comments do |t|
      t.belongs_to :author, null: false
      t.belongs_to :blog_post, null: false
      t.text :body, null: false

      t.timestamps null: false
    end
  end
end
