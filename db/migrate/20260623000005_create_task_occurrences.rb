class CreateTaskOccurrences < ActiveRecord::Migration[7.2]
  def change
    create_table :task_occurrences do |t|
      t.references :task, null: false, foreign_key: { on_delete: :cascade }
      t.date     :occurrence_date, null: false
      t.enum     :status, enum_type: :task_status, default: "pending", null: false
      t.datetime :scheduled_at
      t.string   :name
      t.text     :description
      t.boolean  :cancelled, default: false, null: false

      t.timestamps
    end

    add_index :task_occurrences, %i[task_id occurrence_date], unique: true
    add_index :task_occurrences, :occurrence_date
  end
end
