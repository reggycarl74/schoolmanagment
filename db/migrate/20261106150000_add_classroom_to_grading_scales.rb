class AddClassroomToGradingScales < ActiveRecord::Migration[8.0]
  def change
    remove_index :grading_scales, %i[school_id letter]
    add_reference :grading_scales, :classroom, foreign_key: true
    add_index :grading_scales, %i[school_id classroom_id letter], unique: true, name: "idx_grading_scales_school_class_letter"
  end
end
