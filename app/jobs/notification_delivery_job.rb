class NotificationDeliveryJob < ApplicationJob
  queue_as :default

  def perform(delivery)
    case delivery.channel
    when "email"
      raise ArgumentError, "Recipient does not have an email address" if delivery.recipient.email.blank?

      NotificationMailer.delivery(delivery).deliver_now
    when "sms"
      SmsDeliveryService.call(to: delivery.recipient.phone, body: delivery.body)
    else
      raise ArgumentError, "Unsupported notification channel: #{delivery.channel}"
    end
    delivery.update!(status: :delivered, delivered_at: Time.current)
  rescue StandardError => error
    delivery.update!(status: :failed, error_message: error.message)
    raise
  end
end
