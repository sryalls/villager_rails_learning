class CreateDistributedBatches < ActiveRecord::Migration[7.0]
  def change
    create_table :distributed_batches do |t|
      t.string :name, null: false
      t.text :description
      t.integer :total_chunks, null: false
      t.integer :chunk_size, default: 100
      t.integer :completed_chunks, default: 0
      t.integer :failed_chunks, default: 0
      t.json :chunk_assignments, default: {}
      t.json :chunk_results, default: {}
      t.json :coordination_state, default: {}
      t.integer :status, default: 0
      t.timestamps
    end
    
    add_index :distributed_batches, :status
    add_index :distributed_batches, :created_at
  end
end
