require "test_helper"

class PaymentNotificationServiceTest < ActiveSupport::TestCase
  setup do
    @school = schools(:demo)
    @student = students(:visible)
    fee = @school.fee_structures.create!(academic_year: academic_years(:current), name: "Notification fee", amount: 300, due_on: Date.current + 1.month)
    @invoice = Invoice.create!(student: @student, fee_structure: fee, amount: 300, due_on: fee.due_on)
    @payment = @invoice.payments.create!(amount: 100, paid_on: Date.current, reference: "NOTIFY-#{SecureRandom.hex(4)}", payment_method: :cash, recorded_by: users(:admin))
    @invoice.refresh_status!
  end

  test "queues an email receipt for a guardian who prefers email" do
    guardian = create_guardian(email: "email.parent@example.test", preferred_contact_method: :email)
    queued_delivery = nil

    NotificationDeliveryJob.stub(:perform_later, ->(delivery) { queued_delivery = delivery }) do
      assert_difference("NotificationDelivery.count", 1) { PaymentNotificationService.call(@payment) }
    end

    delivery = guardian.notification_deliveries.last
    assert_equal delivery, queued_delivery
    assert delivery.email?
    assert_includes delivery.body, @payment.receipt_number
    assert_includes delivery.body, @invoice.number
  end

  test "queues an SMS receipt for a guardian who prefers SMS" do
    guardian = create_guardian(email: nil, preferred_contact_method: :sms)
    queued_delivery = nil

    NotificationDeliveryJob.stub(:perform_later, ->(delivery) { queued_delivery = delivery }) { PaymentNotificationService.call(@payment) }

    assert_equal guardian.notification_deliveries.last, queued_delivery
    assert queued_delivery.sms?
  end

  test "does not notify a guardian without billing permission" do
    create_guardian(email: "restricted.parent@example.test", preferred_contact_method: :email, billing_access: false)

    assert_no_difference("NotificationDelivery.count") { PaymentNotificationService.call(@payment) }
  end

  private

  def create_guardian(email:, preferred_contact_method:, billing_access: true)
    guardian = @school.guardians.create!(
      first_name: "Payment",
      last_name: SecureRandom.hex(3),
      email: email,
      phone: "+233201234567",
      preferred_contact_method: preferred_contact_method
    )
    guardian.student_guardians.create!(student: @student, relationship: "Parent", billing_access: billing_access)
    guardian
  end
end
