class ExpandGuardianManagement < ActiveRecord::Migration[8.0]
  def change
    change_table :guardians, bulk: true do |t|
      t.string :alternate_phone
      t.string :preferred_language, null: false, default: "English"
      t.integer :preferred_contact_method, null: false, default: 1
      t.string :occupation
      t.boolean :active, null: false, default: true
      t.text :private_notes
    end

    change_table :student_guardians, bulk: true do |t|
      t.boolean :emergency_contact, null: false, default: false
      t.integer :emergency_priority
      t.boolean :lives_with_student, null: false, default: false
      t.boolean :financially_responsible, null: false, default: false
      t.boolean :academic_access, null: false, default: true
      t.boolean :attendance_access, null: false, default: true
      t.boolean :billing_access, null: false, default: true
      t.boolean :contact_allowed, null: false, default: true
      t.text :custody_restrictions
      t.text :pickup_notes
    end

    add_index :guardians, [ :school_id, :email ]
    add_index :guardians, [ :school_id, :active ]
    add_index :student_guardians, [ :student_id, :primary_contact ]
    add_index :student_guardians, [ :student_id, :emergency_priority ]
  end
end
