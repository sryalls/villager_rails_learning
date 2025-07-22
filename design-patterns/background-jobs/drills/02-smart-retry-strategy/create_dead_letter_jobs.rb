class CreateDeadLetterJobs < ActiveRecord::Migration[7.0]
  def change
    create_table :dead_letter_jobs do |t|
      t.string :job_class, null: false
      t.json :arguments, default: []
      t.text :error_message
      t.text :error_backtrace
      t.integer :retry_count, default: 0
      t.timestamp :failed_at, null: false
      t.json :metadata, default: {}
      t.timestamps
    end

    add_index :dead_letter_jobs, :job_class
    add_index :dead_letter_jobs, :failed_at
  end
end
