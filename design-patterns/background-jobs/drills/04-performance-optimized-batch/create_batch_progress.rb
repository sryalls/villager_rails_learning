class CreateBatchProgress < ActiveRecord::Migration[7.0]
  def change
    create_table :batch_progresses do |t|
      t.references :processing_batch, null: false, foreign_key: true
      t.integer :items_processed, default: 0
      t.integer :items_failed, default: 0
      t.decimal :completion_percentage, precision: 5, scale: 2, default: 0
      t.timestamp :started_at
      t.timestamp :estimated_completion_at
      t.decimal :items_per_second, precision: 10, scale: 2
      t.json :performance_metrics, default: {}
      t.timestamps
    end
    
    add_index :batch_progresses, :processing_batch_id
    add_index :batch_progresses, :created_at
  end
end
