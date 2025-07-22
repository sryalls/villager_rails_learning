class CreateGameWorkflows < ActiveRecord::Migration[7.0]
  def change
    create_table :game_workflows do |t|
      t.string :workflow_type, null: false
      t.integer :status, default: 0
      t.json :context, default: {}
      t.json :step_results, default: {}
      t.json :completed_steps, default: []
      t.string :current_step
      t.text :error_message
      t.text :error_backtrace
      t.timestamps
    end
    
    add_index :game_workflows, :workflow_type
    add_index :game_workflows, :status
    add_index :game_workflows, :created_at
  end
end
