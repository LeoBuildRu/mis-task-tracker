class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_enum :task_status, %w[pending in_progress completed cancelled]

    create_table :tasks do |t|
      t.string :name, null: false
      t.text :description
      t.datetime :scheduled_at, null: false
      t.enum :status, enum_type: :task_status, default: "pending", null: false
      t.references :recurrence_rule, foreign_key: { on_delete: :nullify }

      t.timestamps
    end

    add_index :tasks, :scheduled_at
    add_index :tasks, :status
  end
end
