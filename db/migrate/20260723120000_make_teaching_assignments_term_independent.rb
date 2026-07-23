class MakeTeachingAssignmentsTermIndependent < ActiveRecord::Migration[8.0]
  def up
    add_reference :teaching_assignments, :classroom, foreign_key: true
    add_reference :teaching_assignments, :subject, foreign_key: true

    execute <<~SQL.squish
      UPDATE teaching_assignments
      INNER JOIN course_sections ON course_sections.id = teaching_assignments.course_section_id
      SET teaching_assignments.classroom_id = course_sections.classroom_id,
          teaching_assignments.subject_id = course_sections.subject_id
    SQL

    # Older data may contain one copy of the same assignment for several terms.
    execute <<~SQL.squish
      DELETE duplicate_assignment
      FROM teaching_assignments duplicate_assignment
      INNER JOIN teaching_assignments keeper
        ON keeper.teacher_id = duplicate_assignment.teacher_id
       AND keeper.classroom_id = duplicate_assignment.classroom_id
       AND keeper.subject_id = duplicate_assignment.subject_id
       AND keeper.id < duplicate_assignment.id
    SQL

    change_column_null :teaching_assignments, :classroom_id, false
    change_column_null :teaching_assignments, :subject_id, false
    change_column_null :teaching_assignments, :course_section_id, true
    execute "UPDATE teaching_assignments SET course_section_id = NULL"
    remove_index :teaching_assignments, [ :course_section_id, :teacher_id ]
    add_index :teaching_assignments, [ :teacher_id, :classroom_id, :subject_id ], unique: true, name: "idx_teacher_class_subject_assignment"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Term-specific duplicate assignments were consolidated"
  end
end
