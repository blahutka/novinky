class CreateAdvertisement < ActiveRecord::Migration
  def self.up
    create_table :advertisements, :force => true do |t|
      t.string :module_name
      t.string :banner_size, :default => '468x60'
      t.boolean :active, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :advertisements
  end
end
