class ExpandLessonNotesIntoPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :lesson_notes, :objectives, :text
    add_column :lesson_notes, :materials, :text
    add_column :lesson_notes, :starts_at, :time
    add_column :lesson_notes, :duration_minutes, :integer
    add_column :lesson_notes, :status, :integer, null: false, default: 0
    add_index :lesson_notes, %i[teacher_id lesson_date status]
  end
end
