class Assessment < ApplicationRecord
  belongs_to :course_section
  has_many :grades, dependent: :destroy

  enum :kind, { assignment: 0, quiz: 1, exam: 2, project: 3 }
  enum :status, { draft: 0, submitted: 1, approved: 2, published: 3 }

  validates :title, :due_on, presence: true
  validates :maximum_points, numericality: { greater_than: 0 }
  validates :weight, numericality: { greater_than: 0 }
end
