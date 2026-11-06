class AddReportTemplateToClassrooms < ActiveRecord::Migration[8.0]
  def change
    add_column :classrooms, :report_template, :integer, default: 0, null: false
  end
end
