class NotificationDelivery < ApplicationRecord
  belongs_to :school
  belongs_to :recipient, polymorphic: true
  enum :channel, { email: 0, sms: 1 }
  enum :status, { pending: 0, delivered: 1, failed: 2 }
  validates :subject, :body, presence: true
end
