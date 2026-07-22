class CreateReportCardRemarkTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :report_card_remark_templates do |t|
      t.references :school, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :body, null: false
      t.integer :kind, null: false, default: 1
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :report_card_remark_templates, %i[school_id title], unique: true, name: "index_remark_templates_on_school_and_title"
  end
end
