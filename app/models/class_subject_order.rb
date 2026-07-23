class ClassSubjectOrder < ApplicationRecord
  belongs_to :classroom
  belongs_to :subject

  validates :subject_id, uniqueness: { scope: :classroom_id }
  validates :position, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :classroom_id }
end
