class School < ApplicationRecord
  has_one_attached :logo
  has_many :users, dependent: :destroy
  has_many :academic_years, dependent: :destroy
  has_many :grade_levels, dependent: :destroy
  has_many :teachers, dependent: :destroy
  has_many :classrooms, dependent: :destroy
  has_many :students, dependent: :destroy
  has_many :guardians, dependent: :destroy
  has_many :subjects, dependent: :destroy
  has_many :assessment_components, dependent: :destroy
  has_many :grading_scales, dependent: :destroy
  has_many :announcements, dependent: :destroy
  has_many :fee_structures, dependent: :destroy
  has_many :audit_events, dependent: :destroy
  has_many :report_card_remark_templates, dependent: :destroy

  validates :name, :code, :time_zone, presence: true
  validates :code, uniqueness: true
  validate :acceptable_logo

  private

  def acceptable_logo
    return unless logo.attached?

    errors.add(:logo, "must be a PNG, JPEG, or WebP image") unless logo.content_type.in?(%w[image/png image/jpeg image/webp])
    errors.add(:logo, "must be smaller than 5 MB") if logo.byte_size > 5.megabytes
  end
end
