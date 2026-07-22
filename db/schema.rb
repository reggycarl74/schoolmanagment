# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_07_20_230000) do
  create_table "academic_years", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "name", null: false
    t.date "starts_on", null: false
    t.date "ends_on", null: false
    t.boolean "current", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "name"], name: "index_academic_years_on_school_id_and_name", unique: true
    t.index ["school_id"], name: "index_academic_years_on_school_id"
  end

  create_table "assessments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "course_section_id", null: false
    t.string "title", null: false
    t.integer "kind", default: 0, null: false
    t.decimal "maximum_points", precision: 8, scale: 2, null: false
    t.decimal "weight", precision: 5, scale: 2, default: "1.0", null: false
    t.date "due_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_section_id"], name: "index_assessments_on_course_section_id"
  end

  create_table "attendance_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "enrollment_id", null: false
    t.date "attendance_date", null: false
    t.integer "status", default: 0, null: false
    t.string "notes"
    t.bigint "recorded_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enrollment_id", "attendance_date"], name: "index_attendance_records_on_enrollment_id_and_attendance_date", unique: true
    t.index ["enrollment_id"], name: "index_attendance_records_on_enrollment_id"
    t.index ["recorded_by_id"], name: "index_attendance_records_on_recorded_by_id"
  end

  create_table "classrooms", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "academic_year_id", null: false
    t.bigint "grade_level_id", null: false
    t.bigint "homeroom_teacher_id"
    t.string "name", null: false
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["academic_year_id", "name"], name: "index_classrooms_on_academic_year_id_and_name", unique: true
    t.index ["academic_year_id"], name: "index_classrooms_on_academic_year_id"
    t.index ["grade_level_id"], name: "index_classrooms_on_grade_level_id"
    t.index ["homeroom_teacher_id"], name: "index_classrooms_on_homeroom_teacher_id"
    t.index ["school_id"], name: "index_classrooms_on_school_id"
  end

  create_table "course_sections", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "classroom_id", null: false
    t.bigint "subject_id", null: false
    t.bigint "term_id", null: false
    t.string "room"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id", "subject_id", "term_id"], name: "idx_on_classroom_id_subject_id_term_id_61facd7c34", unique: true
    t.index ["classroom_id"], name: "index_course_sections_on_classroom_id"
    t.index ["subject_id"], name: "index_course_sections_on_subject_id"
    t.index ["term_id"], name: "index_course_sections_on_term_id"
  end

  create_table "enrollments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "classroom_id", null: false
    t.date "enrolled_on", null: false
    t.date "left_on"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id"], name: "index_enrollments_on_classroom_id"
    t.index ["student_id", "classroom_id"], name: "index_enrollments_on_student_id_and_classroom_id", unique: true
    t.index ["student_id"], name: "index_enrollments_on_student_id"
  end

  create_table "grade_levels", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "name"], name: "index_grade_levels_on_school_id_and_name", unique: true
    t.index ["school_id", "position"], name: "index_grade_levels_on_school_id_and_position", unique: true
    t.index ["school_id"], name: "index_grade_levels_on_school_id"
  end

  create_table "grades", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "assessment_id", null: false
    t.bigint "enrollment_id", null: false
    t.decimal "points", precision: 8, scale: 2
    t.text "feedback"
    t.bigint "graded_by_id"
    t.datetime "graded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id", "enrollment_id"], name: "index_grades_on_assessment_id_and_enrollment_id", unique: true
    t.index ["assessment_id"], name: "index_grades_on_assessment_id"
    t.index ["enrollment_id"], name: "index_grades_on_enrollment_id"
    t.index ["graded_by_id"], name: "index_grades_on_graded_by_id"
  end

  create_table "guardians", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "phone", null: false
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "phone"], name: "index_guardians_on_school_id_and_phone"
    t.index ["school_id"], name: "index_guardians_on_school_id"
  end

  create_table "schools", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "time_zone", default: "UTC", null: false
    t.string "email"
    t.string "phone"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_schools_on_code", unique: true
  end

  create_table "student_guardians", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "guardian_id", null: false
    t.string "relationship", null: false
    t.boolean "primary_contact", default: false, null: false
    t.boolean "pickup_authorized", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guardian_id"], name: "index_student_guardians_on_guardian_id"
    t.index ["student_id", "guardian_id"], name: "index_student_guardians_on_student_id_and_guardian_id", unique: true
    t.index ["student_id"], name: "index_student_guardians_on_student_id"
  end

  create_table "students", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "admission_number", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.date "date_of_birth", null: false
    t.integer "gender", null: false
    t.date "admitted_on", null: false
    t.integer "status", default: 0, null: false
    t.text "medical_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "admission_number"], name: "index_students_on_school_id_and_admission_number", unique: true
    t.index ["school_id", "last_name", "first_name"], name: "index_students_on_school_id_and_last_name_and_first_name"
    t.index ["school_id"], name: "index_students_on_school_id"
  end

  create_table "subjects", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "name", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "code"], name: "index_subjects_on_school_id_and_code", unique: true
    t.index ["school_id"], name: "index_subjects_on_school_id"
  end

  create_table "teachers", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "user_id"
    t.string "employee_number", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "phone"
    t.date "hired_on"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "employee_number"], name: "index_teachers_on_school_id_and_employee_number", unique: true
    t.index ["school_id"], name: "index_teachers_on_school_id"
    t.index ["user_id"], name: "index_teachers_on_user_id", unique: true
  end

  create_table "teaching_assignments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "course_section_id", null: false
    t.bigint "teacher_id", null: false
    t.boolean "lead", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_section_id", "teacher_id"], name: "index_teaching_assignments_on_course_section_id_and_teacher_id", unique: true
    t.index ["course_section_id"], name: "index_teaching_assignments_on_course_section_id"
    t.index ["teacher_id"], name: "index_teaching_assignments_on_teacher_id"
  end

  create_table "terms", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "academic_year_id", null: false
    t.string "name", null: false
    t.date "starts_on", null: false
    t.date "ends_on", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["academic_year_id", "position"], name: "index_terms_on_academic_year_id_and_position", unique: true
    t.index ["academic_year_id"], name: "index_terms_on_academic_year_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 2, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "email"], name: "index_users_on_school_id_and_email", unique: true
    t.index ["school_id"], name: "index_users_on_school_id"
  end

  add_foreign_key "academic_years", "schools"
  add_foreign_key "assessments", "course_sections"
  add_foreign_key "attendance_records", "enrollments"
  add_foreign_key "attendance_records", "users", column: "recorded_by_id"
  add_foreign_key "classrooms", "academic_years"
  add_foreign_key "classrooms", "grade_levels"
  add_foreign_key "classrooms", "schools"
  add_foreign_key "classrooms", "teachers", column: "homeroom_teacher_id"
  add_foreign_key "course_sections", "classrooms"
  add_foreign_key "course_sections", "subjects"
  add_foreign_key "course_sections", "terms"
  add_foreign_key "enrollments", "classrooms"
  add_foreign_key "enrollments", "students"
  add_foreign_key "grade_levels", "schools"
  add_foreign_key "grades", "assessments"
  add_foreign_key "grades", "enrollments"
  add_foreign_key "grades", "users", column: "graded_by_id"
  add_foreign_key "guardians", "schools"
  add_foreign_key "student_guardians", "guardians"
  add_foreign_key "student_guardians", "students"
  add_foreign_key "students", "schools"
  add_foreign_key "subjects", "schools"
  add_foreign_key "teachers", "schools"
  add_foreign_key "teachers", "users"
  add_foreign_key "teaching_assignments", "course_sections"
  add_foreign_key "teaching_assignments", "teachers"
  add_foreign_key "terms", "academic_years"
  add_foreign_key "users", "schools"
end
