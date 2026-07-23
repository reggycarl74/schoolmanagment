class AddOperationalRobustness < ActiveRecord::Migration[8.0]
  def change
    change_table :attendance_records, bulk: true do |t|
      t.time :arrived_at
      t.time :departed_at
      t.string :absence_reason
      t.boolean :guardian_notified, null: false, default: false
    end

    change_table :payments, bulk: true do |t|
      t.datetime :reconciled_at
      t.references :reconciled_by, foreign_key: { to_table: :users }
      t.string :reconciliation_reference
    end

    create_table :promotion_batches do |t|
      t.references :school, null: false, foreign_key: true
      t.references :from_classroom, null: false, foreign_key: { to_table: :classrooms }
      t.references :to_classroom, null: false, foreign_key: { to_table: :classrooms }
      t.references :initiated_by, null: false, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.references :reversed_by, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.text :reason
      t.datetime :approved_at
      t.datetime :reversed_at
      t.timestamps
    end

    create_table :promotion_items do |t|
      t.references :promotion_batch, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.references :source_enrollment, null: false, foreign_key: { to_table: :enrollments }
      t.references :destination_enrollment, foreign_key: { to_table: :enrollments }
      t.timestamps
      t.index [ :promotion_batch_id, :student_id ], unique: true
    end
  end
end
