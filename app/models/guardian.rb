class Guardian < ApplicationRecord
  belongs_to :school
  has_many :student_guardians, dependent: :destroy
  has_many :students, through: :student_guardians
  has_one :user, dependent: :nullify

  validates :first_name, :last_name, :phone, presence: true
  def full_name = "#{first_name} #{last_name}"
end
