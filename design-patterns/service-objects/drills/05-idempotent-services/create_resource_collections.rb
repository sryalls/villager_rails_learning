# Migration for tracking collections
class CreateResourceCollections < ActiveRecord::Migration[7.0]
  def change
    create_table :resource_collections do |t|
      t.references :village, null: false, foreign_key: true
      t.string :idempotency_key, null: false
      t.string :collection_type, null: false
      t.json :resources_collected
      t.timestamp :collected_at, null: false
      t.timestamps
    end

    add_index :resource_collections, :idempotency_key, unique: true
    add_index :resource_collections, [:village_id, :collected_at]

    # TODO: Consider additional indexes for performance
    # TODO: Add any other constraints or columns needed
  end
end
