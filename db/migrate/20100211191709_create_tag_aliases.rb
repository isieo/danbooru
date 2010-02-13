class CreateTagAliases < ActiveRecord::Migration
  def self.up
    create_table :tag_aliases do |t|
      t.column :antecedent_name, :string, :null => false
      t.column :consequent_name, :string, :null => false
      t.column :creator_id, :integer, :null => false
      t.column :request_ids, :string
      t.timestamps
    end
    
    add_index :tag_aliases, :antecedent_name
    add_index :tag_aliases, :consequent_name
  end

  def self.down
    drop_table :tag_aliases
  end
end