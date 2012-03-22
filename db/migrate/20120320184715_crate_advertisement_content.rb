class CrateAdvertisementContent < ActiveRecord::Migration
  def self.up
    create_table :advertisement_contents, :force => true do |t|
      t.integer :advertisement_id
      t.string :advertiser_name
      t.string :link, :default => 'http://'
      t.text :note
      t.integer :viewed_num
      t.boolean :active, :default => true
      t.date :date_start
      t.date :date_finish
      t.timestamps
    end
    Advertisement.create!(:module_name => 'home_page')
  end

  def self.down
    drop_table :advertisement_contents
  end
end
