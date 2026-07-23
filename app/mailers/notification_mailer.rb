class NotificationMailer < ApplicationMailer
  def delivery(notification_delivery)
    @delivery = notification_delivery
    @recipient = notification_delivery.recipient
    mail(to: @recipient.email, subject: notification_delivery.subject)
  end
end
