class CreateArticleSelections < ActiveRecord::Migration
  def self.up
    create_table "article_selections", :force => true do |t|
      t.integer "section_id"
      t.integer "article_id"
      t.string "sidebar_articles_ids"
      t.date "publish_date"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
    drop_table :article_selections
  end
end
