class AddAccessToActivity < ActiveRecord::Migration
  def self.up
    remove_column :activities, :public
    add_column :activities, :access, :integer, :default => Activity::DEFAULT, :limit => 1
    remove_index :activities, :name => 'subject_0_4_0'
    execute "CREATE INDEX subject_0_4_0 ON activities (subject_id, subject_type, access)"
  end

  def self.down
    remove_column :activities, :access
    add_column :activities, :public, :boolean
    execute "CREATE INDEX subject_0_4_0 ON activities (subject_id, subject_type, public)"
  end
end
