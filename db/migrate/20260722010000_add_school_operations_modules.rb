class AddSchoolOperationsModules < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :guardian, foreign_key: true, index: { unique: true }
    add_reference :users, :student, foreign_key: true, index: { unique: true }
    add_column :assessments, :status, :integer, null: false, default: 0
    add_column :assessments, :published_at, :datetime

    create_table :assessment_components do |t|
      t.references :school, null: false, foreign_key: true
      t.string :title, null: false
      t.decimal :maximum_points, precision: 8, scale: 2, null: false
      t.integer :kind, null: false, default: 0
      t.integer :position, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :assessment_components, %i[school_id title], unique: true

    create_table :grading_scales do |t|
      t.references :school, null: false, foreign_key: true
      t.string :letter, null: false
      t.decimal :minimum_percentage, precision: 5, scale: 2, null: false
      t.string :remark
      t.timestamps
    end
    add_index :grading_scales, %i[school_id letter], unique: true

    create_table :timetable_entries do |t|
      t.references :course_section, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: true
      t.integer :weekday, null: false
      t.integer :period, null: false
      t.time :starts_at, null: false
      t.time :ends_at, null: false
      t.string :room
      t.timestamps
    end
    add_index :timetable_entries, %i[teacher_id weekday period], unique: true
    add_index :timetable_entries, %i[course_section_id weekday period], unique: true, name: "index_timetable_on_course_weekday_period"

    create_table :announcements do |t|
      t.references :school, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :body, null: false
      t.integer :audience, null: false, default: 0
      t.datetime :published_at, null: false
      t.timestamps
    end

    create_table :fee_structures do |t|
      t.references :school, null: false, foreign_key: true
      t.references :academic_year, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :due_on, null: false
      t.timestamps
    end

    create_table :invoices do |t|
      t.references :student, null: false, foreign_key: true
      t.references :fee_structure, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :status, null: false, default: 0
      t.date :due_on, null: false
      t.timestamps
    end
    add_index :invoices, %i[student_id fee_structure_id], unique: true

    create_table :payments do |t|
      t.references :invoice, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :paid_on, null: false
      t.string :reference, null: false
      t.integer :payment_method, null: false, default: 0
      t.timestamps
    end
    add_index :payments, :reference, unique: true

    create_table :audit_events do |t|
      t.references :school, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.references :auditable, polymorphic: true, null: false
      t.string :action, null: false
      t.json :changes_data
      t.timestamps
    end
    add_index :audit_events, %i[school_id created_at]

    create_table :active_storage_blobs do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum
      t.datetime :created_at, null: false
      t.index :key, unique: true
    end

    create_table :active_storage_attachments do |t|
      t.string :name, null: false
      t.references :record, null: false, polymorphic: true, index: false
      t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }
      t.datetime :created_at, null: false
      t.index %i[record_type record_id name blob_id], unique: true, name: :index_active_storage_attachments_uniqueness
    end

    create_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false
      t.string :variation_digest, null: false
      t.index %i[blob_id variation_digest], unique: true, name: :index_active_storage_variant_records_uniqueness
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end
end
