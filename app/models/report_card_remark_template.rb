class ReportCardRemarkTemplate < ApplicationRecord
  belongs_to :school
  belongs_to :author, class_name: "User"

  enum :kind, ReportCardComment.kinds.transform_values(&:to_i)
  validates :title, :body, presence: true
  validates :title, uniqueness: { scope: :school_id }
  scope :available, -> { where(active: true).order(:kind, :title) }
end
