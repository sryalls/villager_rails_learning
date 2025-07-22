class CreateCircuitBreakerStates < ActiveRecord::Migration[7.0]
  def change
    create_table :circuit_breaker_states do |t|
      t.string :name, null: false
      t.integer :failure_count, default: 0
      t.timestamp :last_failure_at
      t.integer :state, default: 0 # 0: closed, 1: open, 2: half_open
      t.timestamps
    end
    
    add_index :circuit_breaker_states, :name, unique: true
  end
end
