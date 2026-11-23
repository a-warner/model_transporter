ActiveRecord::Schema.define(version: 2021_01_19_003658) do
  create_table "blog_posts", force: :cascade do |t|
    t.string "title", null: false
    t.text "body"
    t.datetime "published_at"
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "comments_count", default: 0, null: false
    t.integer "collection_id"
    t.index ["author_id"], name: "index_blog_posts_on_author_id"
    t.index ["collection_id"], name: "index_blog_posts_on_collection_id"
  end

  create_table "collections", force: :cascade do |t|
    t.string "name", null: false
    t.integer "blog_posts_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "comments", force: :cascade do |t|
    t.integer "author_id", null: false
    t.integer "blog_post_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["blog_post_id"], name: "index_comments_on_blog_post_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
