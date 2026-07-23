class PaymentNotificationService
  def self.call(payment)
    new(payment).call
  end

  def initialize(payment)
    @payment = payment
    @invoice = payment.invoice
    @school = @invoice.student.school
  end

  def call
    billing_guardians.find_each.filter_map do |guardian|
      channel = delivery_channel(guardian)
      next unless channel

      delivery = NotificationDelivery.create!(
        school: @school,
        recipient: guardian,
        source: @payment,
        channel: channel,
        subject: "Payment receipt #{@payment.receipt_number}",
        body: message_body
      )
      enqueue(delivery)
      delivery
    end
  end

  private

  def billing_guardians
    @invoice.student.guardians.merge(StudentGuardian.for_billing).where(active: true)
  end

  def delivery_channel(guardian)
    return :email if guardian.contact_by_email? && guardian.email.present?
    return :sms if guardian.phone.present?
    return :email if guardian.email.present?

    nil
  end

  def enqueue(delivery)
    NotificationDeliveryJob.perform_later(delivery)
  rescue StandardError => error
    delivery.update!(status: :failed, error_message: "Could not queue delivery: #{error.message}")
    Rails.logger.error("Payment notification #{delivery.id} could not be queued: #{error.message}")
  end

  def message_body
    "#{@school.name}: payment of #{money(@payment.amount)} received for #{@invoice.student.full_name}. " \
      "Receipt #{@payment.receipt_number}; invoice #{@invoice.number}; balance #{money(@invoice.balance)}. " \
      "View receipt: #{receipt_url}"
  end

  def money(amount)
    "#{@school.currency_code} #{format('%.2f', amount)}"
  end

  def receipt_url
    Rails.application.routes.url_helpers.invoice_payment_url(
      @invoice,
      @payment,
      host: ENV.fetch("APP_HOST", "school-management-system-c8d2.onrender.com"),
      protocol: "https"
    )
  end
end
