class AddReportCardBranding < ActiveRecord::Migration[8.0]
  def change
    add_column :terms, :reopening_date, :date
  end
end
