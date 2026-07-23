class ExpandAcademicOperations < ActiveRecord::Migration[8.0]
  def change
    add_reference :assessment_components, :classroom, foreign_key: true
    remove_index :assessment_components, [ :school_id, :title ]
    add_index :assessment_components, [ :school_id, :classroom_id, :title ], unique: true, name: "idx_assessment_components_school_class_title"

    add_reference :classrooms, :result_entry_term, foreign_key: { to_table: :terms }

    create_table :class_subject_orders do |t|
      t.references :classroom, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.integer :position, null: false
      t.timestamps
      t.index [ :classroom_id, :subject_id ], unique: true
      t.index [ :classroom_id, :position ], unique: true
    end

    change_table :announcements, bulk: true do |t|
      t.boolean :send_email, null: false, default: false
      t.boolean :send_sms, null: false, default: false
    end

    change_table :fee_structures, bulk: true do |t|
      t.integer :frequency, null: false, default: 0
      t.date :starts_on
      t.date :ends_on
      t.boolean :active, null: false, default: true
    end

    add_column :invoices, :charge_on, :date
    remove_index :invoices, [ :student_id, :fee_structure_id ]
    add_index :invoices, [ :student_id, :fee_structure_id, :charge_on ], unique: true, name: "idx_invoices_student_fee_charge_date"

    create_table :classroom_posts do |t|
      t.references :course_section, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.integer :kind, null: false, default: 0
      t.string :title, null: false
      t.text :body
      t.datetime :due_at
      t.datetime :published_at, null: false
      t.timestamps
      t.index [ :course_section_id, :published_at ]
    end

    create_table :student_submissions do |t|
      t.references :classroom_post, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.text :body
      t.integer :status, null: false, default: 0
      t.datetime :submitted_at
      t.decimal :score, precision: 8, scale: 2
      t.text :feedback
      t.timestamps
      t.index [ :classroom_post_id, :student_id ], unique: true
    end

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE assessment_components
          SET position = CASE title
            WHEN 'Class Work' THEN 1
            WHEN 'Class Test' THEN 2
            WHEN 'Project' THEN 3
            WHEN 'Mid Term' THEN 4
            WHEN 'Exam' THEN 5
            ELSE position
          END
        SQL
      end
    end
  end
end
