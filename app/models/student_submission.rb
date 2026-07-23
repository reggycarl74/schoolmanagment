class StudentSubmission < ApplicationRecord
  belongs_to :classroom_post
  belongs_to :student
  has_many_attached :files

  enum :status, { draft: 0, submitted: 1, returned: 2, graded: 3 }
  validates :student_id, uniqueness: { scope: :classroom_post_id }
end
