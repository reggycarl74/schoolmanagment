class Guardian < ApplicationRecord
  include AuditableChanges
  belongs_to :school
  has_many :student_guardians, dependent: :destroy
  has_many :students, through: :student_guardians
  has_one :user, dependent: :nullify

  enum :preferred_contact_method, { email: 0, phone: 1, sms: 2, whatsapp: 3 }, prefix: :contact_by

  normalizes :email, with: ->(email) { email.to_s.strip.downcase.presence }
  normalizes :phone, :alternate_phone, with: ->(phone) { phone.to_s.strip.presence }
  validates :first_name, :last_name, :phone, presence: true
  validates :email, uniqueness: { scope: :school_id, allow_blank: true }
  validate :email_required_for_email_contact

  def full_name = "#{first_name} #{last_name}"
  def portal_status = user.nil? ? "not_invited" : user.active? ? "active" : "disabled"

  private

  def audit_school = school

  def email_required_for_email_contact
    errors.add(:email, "is required when email is the preferred contact method") if contact_by_email? && email.blank?
  end
end
