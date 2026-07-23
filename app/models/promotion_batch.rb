class PromotionBatch < ApplicationRecord
  belongs_to :school
  belongs_to :from_classroom, class_name: "Classroom"
  belongs_to :to_classroom, class_name: "Classroom"
  belongs_to :initiated_by, class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :reversed_by, class_name: "User", optional: true
  has_many :promotion_items, dependent: :destroy

  enum :status, { pending: 0, approved: 1, reversed: 2, rejected: 3 }
  validates :reason, presence: true
  validate :different_classrooms

  def approve!(user)
    raise ActiveRecord::RecordInvalid, self unless pending?

    transaction do
      promotion_items.includes(:student, :source_enrollment).each do |item|
        item.source_enrollment.update!(status: :completed, left_on: Date.current)
        destination = Enrollment.find_or_create_by!(student: item.student, classroom: to_classroom) do |enrollment|
          enrollment.enrolled_on = Date.current
        end
        destination.update!(status: :enrolled, left_on: nil)
        item.update!(destination_enrollment: destination)
      end
      update!(status: :approved, approved_by: user, approved_at: Time.current)
    end
  end

  def reverse!(user)
    raise ActiveRecord::RecordInvalid, self unless approved?

    transaction do
      promotion_items.includes(:source_enrollment, :destination_enrollment).each do |item|
        item.destination_enrollment&.update!(status: :withdrawn, left_on: Date.current)
        item.source_enrollment.update!(status: :enrolled, left_on: nil)
      end
      update!(status: :reversed, reversed_by: user, reversed_at: Time.current)
    end
  end

  private

  def different_classrooms
    errors.add(:to_classroom, "must be different from the current class") if from_classroom_id == to_classroom_id
  end
end
