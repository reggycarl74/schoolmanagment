class Student < ApplicationRecord
  belongs_to :school
  has_many :student_guardians, dependent: :destroy
  has_many :guardians, through: :student_guardians
  has_many :enrollments, dependent: :restrict_with_error
  has_many :classrooms, through: :enrollments
  has_one :user, dependent: :nullify
  has_many_attached :documents
  has_many :invoices, dependent: :restrict_with_error
  has_many :report_card_comments, dependent: :destroy
  has_many :student_submissions, dependent: :destroy

  enum :gender, { female: 0, male: 1, non_binary: 2, undisclosed: 3 }
  enum :status, { active: 0, graduated: 1, transferred: 2, withdrawn: 3 }

  validates :admission_number, :first_name, :last_name, :date_of_birth, :admitted_on, presence: true
  validates :admission_number, uniqueness: { scope: :school_id }

  def full_name = "#{first_name} #{last_name}"
  def billing_balance = billing_opening_balance + invoices.where.not(status: :cancelled).to_a.sum(&:balance)
end
