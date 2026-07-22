class CreateSchoolManagementCore < ActiveRecord::Migration[8.0]
  def change
    create_table :schools do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :time_zone, null: false, default: "UTC"
      t.string :email
      t.string :phone
      t.text :address
      t.timestamps
    end
    add_index :schools, :code, unique: true

    create_table :users do |t|
      t.references :school, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.integer :role, null: false, default: 2
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :users, %i[school_id email], unique: true

    create_table :academic_years do |t|
      t.references :school, null: false, foreign_key: true
      t.string :name, null: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.boolean :current, null: false, default: false
      t.timestamps
    end
    add_index :academic_years, %i[school_id name], unique: true

    create_table :terms do |t|
      t.references :academic_year, null: false, foreign_key: true
      t.string :name, null: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.integer :position, null: false
      t.timestamps
    end
    add_index :terms, %i[academic_year_id position], unique: true

    create_table :grade_levels do |t|
      t.references :school, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false
      t.timestamps
    end
    add_index :grade_levels, %i[school_id name], unique: true
    add_index :grade_levels, %i[school_id position], unique: true

    create_table :teachers do |t|
      t.references :school, null: false, foreign_key: true
      t.references :user, foreign_key: true, index: { unique: true }
      t.string :employee_number, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone
      t.date :hired_on
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :teachers, %i[school_id employee_number], unique: true

    create_table :classrooms do |t|
      t.references :school, null: false, foreign_key: true
      t.references :academic_year, null: false, foreign_key: true
      t.references :grade_level, null: false, foreign_key: true
      t.references :homeroom_teacher, foreign_key: { to_table: :teachers }
      t.string :name, null: false
      t.integer :capacity
      t.timestamps
    end
    add_index :classrooms, %i[academic_year_id name], unique: true

    create_table :students do |t|
      t.references :school, null: false, foreign_key: true
      t.string :admission_number, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.date :date_of_birth, null: false
      t.integer :gender, null: false
      t.date :admitted_on, null: false
      t.integer :status, null: false, default: 0
      t.text :medical_notes
      t.timestamps
    end
    add_index :students, %i[school_id admission_number], unique: true
    add_index :students, %i[school_id last_name first_name]

    create_table :guardians do |t|
      t.references :school, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone, null: false
      t.text :address
      t.timestamps
    end
    add_index :guardians, %i[school_id phone]

    create_table :student_guardians do |t|
      t.references :student, null: false, foreign_key: true
      t.references :guardian, null: false, foreign_key: true
      t.string :relationship, null: false
      t.boolean :primary_contact, null: false, default: false
      t.boolean :pickup_authorized, null: false, default: true
      t.timestamps
    end
    add_index :student_guardians, %i[student_id guardian_id], unique: true

    create_table :enrollments do |t|
      t.references :student, null: false, foreign_key: true
      t.references :classroom, null: false, foreign_key: true
      t.date :enrolled_on, null: false
      t.date :left_on
      t.integer :status, null: false, default: 0
      t.timestamps
    end
    add_index :enrollments, %i[student_id classroom_id], unique: true

    create_table :subjects do |t|
      t.references :school, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code, null: false
      t.timestamps
    end
    add_index :subjects, %i[school_id code], unique: true

    create_table :course_sections do |t|
      t.references :classroom, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.references :term, null: false, foreign_key: true
      t.string :room
      t.timestamps
    end
    add_index :course_sections, %i[classroom_id subject_id term_id], unique: true

    create_table :teaching_assignments do |t|
      t.references :course_section, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: true
      t.boolean :lead, null: false, default: true
      t.timestamps
    end
    add_index :teaching_assignments, %i[course_section_id teacher_id], unique: true

    create_table :attendance_records do |t|
      t.references :enrollment, null: false, foreign_key: true
      t.date :attendance_date, null: false
      t.integer :status, null: false, default: 0
      t.string :notes
      t.references :recorded_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :attendance_records, %i[enrollment_id attendance_date], unique: true

    create_table :assessments do |t|
      t.references :course_section, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :kind, null: false, default: 0
      t.decimal :maximum_points, precision: 8, scale: 2, null: false
      t.decimal :weight, precision: 5, scale: 2, null: false, default: 1
      t.date :due_on, null: false
      t.timestamps
    end

    create_table :grades do |t|
      t.references :assessment, null: false, foreign_key: true
      t.references :enrollment, null: false, foreign_key: true
      t.decimal :points, precision: 8, scale: 2
      t.text :feedback
      t.references :graded_by, foreign_key: { to_table: :users }
      t.datetime :graded_at
      t.timestamps
    end
    add_index :grades, %i[assessment_id enrollment_id], unique: true
  end
end
