class NotificationDeliveryJob < ApplicationJob
  queue_as :default

  def perform(delivery)
    Rails.logger.info("#{delivery.channel.upcase} notification to #{delivery.recipient_type}##{delivery.recipient_id}: #{delivery.subject}")
    delivery.update!(status: :delivered, delivered_at: Time.current)
  rescue StandardError => error
    delivery.update!(status: :failed, error_message: error.message)
    raise
  end
end
