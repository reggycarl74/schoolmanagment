class AddSchoolExperienceModules < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :discount, :decimal, precision: 12, scale: 2, null: false, default: 0
    add_column :invoices, :discount_reason, :string

    create_table :report_card_comments do |t|
      t.references :student, null: false, foreign_key: true
      t.references :term, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.integer :kind, null: false, default: 0
      t.text :body, null: false
      t.boolean :approved, null: false, default: false
      t.timestamps
    end
    add_index :report_card_comments, %i[student_id term_id kind], unique: true, name: "index_report_comments_on_student_term_kind"

    create_table :login_activities do |t|
      t.references :user, foreign_key: true
      t.string :email, null: false
      t.string :ip_address
      t.string :user_agent
      t.boolean :successful, null: false
      t.timestamps
    end
    add_index :login_activities, :created_at

    create_table :notification_deliveries do |t|
      t.references :school, null: false, foreign_key: true
      t.references :recipient, polymorphic: true, null: false
      t.integer :channel, null: false, default: 0
      t.string :subject, null: false
      t.text :body, null: false
      t.integer :status, null: false, default: 0
      t.datetime :delivered_at
      t.text :error_message
      t.timestamps
    end
  end
end
