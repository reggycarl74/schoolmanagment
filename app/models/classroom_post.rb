class ClassroomPost < ApplicationRecord
  belongs_to :course_section
  belongs_to :author, class_name: "User"
  has_many :student_submissions, dependent: :destroy
  has_many_attached :files

  enum :kind, { announcement: 0, material: 1, assignment: 2 }
  validates :title, :published_at, presence: true
  validates :due_at, presence: true, if: :assignment?
end
