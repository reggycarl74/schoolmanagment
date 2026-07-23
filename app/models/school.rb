class School < ApplicationRecord
  attr_reader :sms_auth_token
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
  has_many :notification_deliveries, dependent: :destroy
  has_many :report_card_remark_templates, dependent: :destroy

  validates :name, :code, :time_zone, presence: true
  validates :code, uniqueness: true
  validates :currency_code, inclusion: { in: %w[USD EUR GBP GHS NGN ZAR KES] }
  validate :acceptable_logo

  def sms_auth_token
    return if sms_auth_token_ciphertext.blank?

    sms_encryptor.decrypt_and_verify(sms_auth_token_ciphertext)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  def sms_auth_token=(value)
    return if value.blank?

    self.sms_auth_token_ciphertext = sms_encryptor.encrypt_and_sign(value)
  end

  def sms_configured?
    sms_account_sid.present? && sms_auth_token.present? && sms_from_number.present?
  end

  private

  def sms_encryptor
    key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key("school-sms-settings", 32)
    ActiveSupport::MessageEncryptor.new(key)
  end

  def acceptable_logo
    return unless logo.attached?

    errors.add(:logo, "must be a PNG, JPEG, or WebP image") unless logo.content_type.in?(%w[image/png image/jpeg image/webp])
    errors.add(:logo, "must be smaller than 5 MB") if logo.byte_size > 5.megabytes
  end
end
