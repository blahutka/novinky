class CreateSections < ActiveRecord::Migration
  def self.up
    create_table :sections, :force => true do |t|
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :sections
  end
end
