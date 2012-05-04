class CreateAvatars < ActiveRecord::Migration
  def self.up
    create_table :avatars do |t|
      t.column :data, :binary, :null => false
      t.column :public, :boolean, :default => false
    end
  end

  def self.down
    drop_table :avatars
  end
end
