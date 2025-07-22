class CreateProcessingBatches < ActiveRecord::Migration[7.0]
  def change
    create_table :processing_batches do |t|
      t.string :name, null: false
      t.text :description
      t.integer :total_items, null: false
      t.integer :processed_items, default: 0
      t.integer :failed_items, default: 0
      t.integer :status, default: 0
      t.json :processing_options, default: {}
      t.json :metadata, default: {}
      t.timestamps
    end
    
    add_index :processing_batches, :status
    add_index :processing_batches, :created_at
  end
end
