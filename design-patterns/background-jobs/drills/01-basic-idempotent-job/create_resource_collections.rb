# Create migration first
class CreateResourceCollections < ActiveRecord::Migration[7.0]
  def change
    create_table :resource_collections do |t|
      t.references :village, null: false, foreign_key: true
      t.string :collection_period, null: false # e.g., "2024-01-15-14" (year-month-day-hour)
      t.json :resources_collected, default: {}
      t.decimal :total_value, precision: 10, scale: 2, default: 0
      t.timestamp :collected_at, null: false
      t.timestamps
    end

    # TODO: Add appropriate indexes for idempotency and performance
  end
end
