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

ActiveRecord::Schema[8.0].define(version: 2026_07_23_110000) do
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

  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "announcements", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "author_id", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.integer "audience", default: 0, null: false
    t.datetime "published_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "send_email", default: false, null: false
    t.boolean "send_sms", default: false, null: false
    t.index ["author_id"], name: "index_announcements_on_author_id"
    t.index ["school_id"], name: "index_announcements_on_school_id"
  end

  create_table "assessment_components", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "title", null: false
    t.decimal "maximum_points", precision: 8, scale: 2, null: false
    t.integer "kind", default: 0, null: false
    t.integer "position", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "classroom_id"
    t.index ["classroom_id"], name: "index_assessment_components_on_classroom_id"
    t.index ["school_id", "classroom_id", "title"], name: "idx_assessment_components_school_class_title", unique: true
    t.index ["school_id"], name: "index_assessment_components_on_school_id"
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
    t.integer "status", default: 0, null: false
    t.datetime "published_at"
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

  create_table "audit_events", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "user_id"
    t.string "auditable_type", null: false
    t.bigint "auditable_id", null: false
    t.string "action", null: false
    t.json "changes_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_events_on_auditable"
    t.index ["school_id", "created_at"], name: "index_audit_events_on_school_id_and_created_at"
    t.index ["school_id"], name: "index_audit_events_on_school_id"
    t.index ["user_id"], name: "index_audit_events_on_user_id"
  end

  create_table "billing_adjustments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.integer "kind", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "reason", null: false
    t.bigint "created_by_id", null: false
    t.bigint "approved_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_billing_adjustments_on_approved_by_id"
    t.index ["created_by_id"], name: "index_billing_adjustments_on_created_by_id"
    t.index ["invoice_id"], name: "index_billing_adjustments_on_invoice_id"
  end

  create_table "class_subject_orders", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "classroom_id", null: false
    t.bigint "subject_id", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id", "position"], name: "index_class_subject_orders_on_classroom_id_and_position", unique: true
    t.index ["classroom_id", "subject_id"], name: "index_class_subject_orders_on_classroom_id_and_subject_id", unique: true
    t.index ["classroom_id"], name: "index_class_subject_orders_on_classroom_id"
    t.index ["subject_id"], name: "index_class_subject_orders_on_subject_id"
  end

  create_table "classroom_posts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "course_section_id", null: false
    t.bigint "author_id", null: false
    t.integer "kind", default: 0, null: false
    t.string "title", null: false
    t.text "body"
    t.datetime "due_at"
    t.datetime "published_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_classroom_posts_on_author_id"
    t.index ["course_section_id", "published_at"], name: "index_classroom_posts_on_course_section_id_and_published_at"
    t.index ["course_section_id"], name: "index_classroom_posts_on_course_section_id"
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
    t.bigint "result_entry_term_id"
    t.index ["academic_year_id", "name"], name: "index_classrooms_on_academic_year_id_and_name", unique: true
    t.index ["academic_year_id"], name: "index_classrooms_on_academic_year_id"
    t.index ["grade_level_id"], name: "index_classrooms_on_grade_level_id"
    t.index ["homeroom_teacher_id"], name: "index_classrooms_on_homeroom_teacher_id"
    t.index ["result_entry_term_id"], name: "index_classrooms_on_result_entry_term_id"
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

  create_table "fee_structures", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "academic_year_id", null: false
    t.string "name", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.date "due_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "frequency", default: 0, null: false
    t.date "starts_on"
    t.date "ends_on"
    t.boolean "active", default: true, null: false
    t.index ["academic_year_id"], name: "index_fee_structures_on_academic_year_id"
    t.index ["school_id"], name: "index_fee_structures_on_school_id"
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

  create_table "grading_scales", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "letter", null: false
    t.decimal "minimum_percentage", precision: 5, scale: 2, null: false
    t.string "remark"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "letter"], name: "index_grading_scales_on_school_id_and_letter", unique: true
    t.index ["school_id"], name: "index_grading_scales_on_school_id"
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
    t.string "alternate_phone"
    t.string "preferred_language", default: "English", null: false
    t.integer "preferred_contact_method", default: 1, null: false
    t.string "occupation"
    t.boolean "active", default: true, null: false
    t.text "private_notes"
    t.index ["school_id", "active"], name: "index_guardians_on_school_id_and_active"
    t.index ["school_id", "email"], name: "index_guardians_on_school_id_and_email"
    t.index ["school_id", "phone"], name: "index_guardians_on_school_id_and_phone"
    t.index ["school_id"], name: "index_guardians_on_school_id"
  end

  create_table "invoice_line_items", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.string "description", null: false
    t.integer "category", default: 0, null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0", null: false
    t.decimal "unit_amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_line_items_on_invoice_id"
  end

  create_table "invoices", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "fee_structure_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.date "due_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "discount", precision: 12, scale: 2, default: "0.0", null: false
    t.string "discount_reason"
    t.string "number", null: false
    t.date "issued_on", null: false
    t.text "notes"
    t.datetime "cancelled_at"
    t.bigint "cancelled_by_id"
    t.date "charge_on"
    t.index ["cancelled_by_id"], name: "index_invoices_on_cancelled_by_id"
    t.index ["fee_structure_id"], name: "index_invoices_on_fee_structure_id"
    t.index ["number"], name: "index_invoices_on_number", unique: true
    t.index ["student_id", "fee_structure_id", "charge_on"], name: "idx_invoices_student_fee_charge_date", unique: true
    t.index ["student_id"], name: "index_invoices_on_student_id"
  end

  create_table "lesson_notes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "course_section_id", null: false
    t.bigint "teacher_id", null: false
    t.date "lesson_date", null: false
    t.string "topic", null: false
    t.text "content", null: false
    t.text "homework"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "objectives"
    t.text "materials"
    t.time "starts_at"
    t.integer "duration_minutes"
    t.integer "status", default: 0, null: false
    t.index ["course_section_id", "teacher_id", "lesson_date"], name: "index_lesson_notes_on_section_teacher_and_date"
    t.index ["course_section_id"], name: "index_lesson_notes_on_course_section_id"
    t.index ["teacher_id", "lesson_date", "status"], name: "index_lesson_notes_on_teacher_id_and_lesson_date_and_status"
    t.index ["teacher_id"], name: "index_lesson_notes_on_teacher_id"
  end

  create_table "login_activities", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.string "email", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.boolean "successful", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_login_activities_on_created_at"
    t.index ["user_id"], name: "index_login_activities_on_user_id"
  end

  create_table "notification_deliveries", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "recipient_type", null: false
    t.bigint "recipient_id", null: false
    t.integer "channel", default: 0, null: false
    t.string "subject", null: false
    t.text "body", null: false
    t.integer "status", default: 0, null: false
    t.datetime "delivered_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source_type"
    t.bigint "source_id"
    t.index ["recipient_type", "recipient_id"], name: "index_notification_deliveries_on_recipient"
    t.index ["school_id"], name: "index_notification_deliveries_on_school_id"
    t.index ["source_type", "source_id"], name: "index_notification_deliveries_on_source"
  end

  create_table "payment_installments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.string "name", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.date "due_on", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id", "due_on"], name: "index_payment_installments_on_invoice_id_and_due_on"
    t.index ["invoice_id"], name: "index_payment_installments_on_invoice_id"
  end

  create_table "payments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.date "paid_on", null: false
    t.string "reference", null: false
    t.integer "payment_method", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "receipt_number", null: false
    t.bigint "recorded_by_id"
    t.datetime "reversed_at"
    t.bigint "reversed_by_id"
    t.text "reversal_reason"
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
    t.index ["receipt_number"], name: "index_payments_on_receipt_number", unique: true
    t.index ["recorded_by_id"], name: "index_payments_on_recorded_by_id"
    t.index ["reference"], name: "index_payments_on_reference", unique: true
    t.index ["reversed_by_id"], name: "index_payments_on_reversed_by_id"
  end

  create_table "report_card_comments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "term_id", null: false
    t.bigint "author_id", null: false
    t.integer "kind", default: 0, null: false
    t.text "body", null: false
    t.boolean "approved", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_report_card_comments_on_author_id"
    t.index ["student_id", "term_id", "kind"], name: "index_report_comments_on_student_term_kind", unique: true
    t.index ["student_id"], name: "index_report_card_comments_on_student_id"
    t.index ["term_id"], name: "index_report_card_comments_on_term_id"
  end

  create_table "report_card_remark_templates", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "author_id", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.integer "kind", default: 1, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_report_card_remark_templates_on_author_id"
    t.index ["school_id", "title"], name: "index_remark_templates_on_school_and_title", unique: true
    t.index ["school_id"], name: "index_report_card_remark_templates_on_school_id"
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
    t.string "currency_code", default: "USD", null: false
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
    t.boolean "emergency_contact", default: false, null: false
    t.integer "emergency_priority"
    t.boolean "lives_with_student", default: false, null: false
    t.boolean "financially_responsible", default: false, null: false
    t.boolean "academic_access", default: true, null: false
    t.boolean "attendance_access", default: true, null: false
    t.boolean "billing_access", default: true, null: false
    t.boolean "contact_allowed", default: true, null: false
    t.text "custody_restrictions"
    t.text "pickup_notes"
    t.index ["guardian_id"], name: "index_student_guardians_on_guardian_id"
    t.index ["student_id", "emergency_priority"], name: "index_student_guardians_on_student_id_and_emergency_priority"
    t.index ["student_id", "guardian_id"], name: "index_student_guardians_on_student_id_and_guardian_id", unique: true
    t.index ["student_id", "primary_contact"], name: "index_student_guardians_on_student_id_and_primary_contact"
    t.index ["student_id"], name: "index_student_guardians_on_student_id"
  end

  create_table "student_submissions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "classroom_post_id", null: false
    t.bigint "student_id", null: false
    t.text "body"
    t.integer "status", default: 0, null: false
    t.datetime "submitted_at"
    t.decimal "score", precision: 8, scale: 2
    t.text "feedback"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_post_id", "student_id"], name: "index_student_submissions_on_classroom_post_id_and_student_id", unique: true
    t.index ["classroom_post_id"], name: "index_student_submissions_on_classroom_post_id"
    t.index ["student_id"], name: "index_student_submissions_on_student_id"
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
    t.decimal "billing_opening_balance", precision: 12, scale: 2, default: "0.0", null: false
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
    t.date "reopening_date"
    t.index ["academic_year_id", "position"], name: "index_terms_on_academic_year_id_and_position", unique: true
    t.index ["academic_year_id"], name: "index_terms_on_academic_year_id"
  end

  create_table "timetable_entries", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "course_section_id", null: false
    t.bigint "teacher_id", null: false
    t.integer "weekday", null: false
    t.integer "period", null: false
    t.time "starts_at", null: false
    t.time "ends_at", null: false
    t.string "room"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_section_id", "weekday", "period"], name: "index_timetable_on_course_weekday_period", unique: true
    t.index ["course_section_id"], name: "index_timetable_entries_on_course_section_id"
    t.index ["teacher_id", "weekday", "period"], name: "index_timetable_entries_on_teacher_id_and_weekday_and_period", unique: true
    t.index ["teacher_id"], name: "index_timetable_entries_on_teacher_id"
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
    t.bigint "guardian_id"
    t.bigint "student_id"
    t.index ["guardian_id"], name: "index_users_on_guardian_id", unique: true
    t.index ["school_id", "email"], name: "index_users_on_school_id_and_email", unique: true
    t.index ["school_id"], name: "index_users_on_school_id"
    t.index ["student_id"], name: "index_users_on_student_id", unique: true
  end

  add_foreign_key "academic_years", "schools"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "announcements", "schools"
  add_foreign_key "announcements", "users", column: "author_id"
  add_foreign_key "assessment_components", "classrooms"
  add_foreign_key "assessment_components", "schools"
  add_foreign_key "assessments", "course_sections"
  add_foreign_key "attendance_records", "enrollments"
  add_foreign_key "attendance_records", "users", column: "recorded_by_id"
  add_foreign_key "audit_events", "schools"
  add_foreign_key "audit_events", "users"
  add_foreign_key "billing_adjustments", "invoices"
  add_foreign_key "billing_adjustments", "users", column: "approved_by_id"
  add_foreign_key "billing_adjustments", "users", column: "created_by_id"
  add_foreign_key "class_subject_orders", "classrooms"
  add_foreign_key "class_subject_orders", "subjects"
  add_foreign_key "classroom_posts", "course_sections"
  add_foreign_key "classroom_posts", "users", column: "author_id"
  add_foreign_key "classrooms", "academic_years"
  add_foreign_key "classrooms", "grade_levels"
  add_foreign_key "classrooms", "schools"
  add_foreign_key "classrooms", "teachers", column: "homeroom_teacher_id"
  add_foreign_key "classrooms", "terms", column: "result_entry_term_id"
  add_foreign_key "course_sections", "classrooms"
  add_foreign_key "course_sections", "subjects"
  add_foreign_key "course_sections", "terms"
  add_foreign_key "enrollments", "classrooms"
  add_foreign_key "enrollments", "students"
  add_foreign_key "fee_structures", "academic_years"
  add_foreign_key "fee_structures", "schools"
  add_foreign_key "grade_levels", "schools"
  add_foreign_key "grades", "assessments"
  add_foreign_key "grades", "enrollments"
  add_foreign_key "grades", "users", column: "graded_by_id"
  add_foreign_key "grading_scales", "schools"
  add_foreign_key "guardians", "schools"
  add_foreign_key "invoice_line_items", "invoices"
  add_foreign_key "invoices", "fee_structures"
  add_foreign_key "invoices", "students"
  add_foreign_key "invoices", "users", column: "cancelled_by_id"
  add_foreign_key "lesson_notes", "course_sections"
  add_foreign_key "lesson_notes", "teachers"
  add_foreign_key "login_activities", "users"
  add_foreign_key "notification_deliveries", "schools"
  add_foreign_key "payment_installments", "invoices"
  add_foreign_key "payments", "invoices"
  add_foreign_key "payments", "users", column: "recorded_by_id"
  add_foreign_key "payments", "users", column: "reversed_by_id"
  add_foreign_key "report_card_comments", "students"
  add_foreign_key "report_card_comments", "terms"
  add_foreign_key "report_card_comments", "users", column: "author_id"
  add_foreign_key "report_card_remark_templates", "schools"
  add_foreign_key "report_card_remark_templates", "users", column: "author_id"
  add_foreign_key "student_guardians", "guardians"
  add_foreign_key "student_guardians", "students"
  add_foreign_key "student_submissions", "classroom_posts"
  add_foreign_key "student_submissions", "students"
  add_foreign_key "students", "schools"
  add_foreign_key "subjects", "schools"
  add_foreign_key "teachers", "schools"
  add_foreign_key "teachers", "users"
  add_foreign_key "teaching_assignments", "course_sections"
  add_foreign_key "teaching_assignments", "teachers"
  add_foreign_key "terms", "academic_years"
  add_foreign_key "timetable_entries", "course_sections"
  add_foreign_key "timetable_entries", "teachers"
  add_foreign_key "users", "guardians"
  add_foreign_key "users", "schools"
  add_foreign_key "users", "students"
end
