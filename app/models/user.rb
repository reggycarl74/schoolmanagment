class User < ApplicationRecord
  belongs_to :school
  belongs_to :guardian, optional: true
  belongs_to :student, optional: true
  has_one :teacher, dependent: :nullify
  has_many :login_activities, dependent: :nullify

  generates_token_for :password_reset, expires_in: 30.minutes do
    password_digest.last(10)
  end

  has_secure_password
  enum :role, { administrator: 0, teacher: 1, registrar: 2, accountant: 3, parent: 4, student: 5 }

  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :first_name, :last_name, :email, presence: true
  validates :email, uniqueness: { scope: :school_id }
  validates :password, length: { minimum: 8 }, allow_nil: true

  def full_name = "#{first_name} #{last_name}"
end
