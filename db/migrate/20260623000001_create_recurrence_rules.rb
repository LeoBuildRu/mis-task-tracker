class CreateRecurrenceRules < ActiveRecord::Migration[7.2]
  def change
    create_enum :recurrence_frequency, %w[daily monthly specific_dates even_days odd_days]

    create_table :recurrence_rules do |t|
      t.enum :frequency, enum_type: :recurrence_frequency, null: false
      t.integer :interval, default: 1, null: false
      t.integer :days_of_month, array: true, default: [], null: false
      t.date :specific_dates, array: true, default: [], null: false
      t.date :starts_on, null: false
      t.date :ends_on

      t.timestamps
    end

    add_index :recurrence_rules, :frequency
    add_index :recurrence_rules, :starts_on
  end
end
