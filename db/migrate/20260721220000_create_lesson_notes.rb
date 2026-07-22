class CreateLessonNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :lesson_notes do |t|
      t.references :course_section, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: true
      t.date :lesson_date, null: false
      t.string :topic, null: false
      t.text :content, null: false
      t.text :homework
      t.timestamps
    end

    add_index :lesson_notes, %i[course_section_id teacher_id lesson_date], name: "index_lesson_notes_on_section_teacher_and_date"
  end
end
