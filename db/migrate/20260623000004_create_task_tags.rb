class CreateTaskTags < ActiveRecord::Migration[7.2]
  def change
    create_table :task_tags do |t|
      t.references :task, null: false, foreign_key: { on_delete: :cascade }
      t.references :tag,  null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :task_tags, %i[task_id tag_id], unique: true
  end
end
