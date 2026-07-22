class BillingReminderJob < ApplicationJob
  queue_as :default

  def perform
    Invoice.includes(student: :guardians).where.not(status: %i[paid cancelled]).find_each do |invoice|
      next unless invoice.due_on <= 7.days.from_now.to_date

      subject = invoice.due_on < Date.current ? "Overdue fee reminder: #{invoice.number}" : "Upcoming fee reminder: #{invoice.number}"
      invoice.student.guardians.each do |guardian|
        next if NotificationDelivery.exists?(recipient: guardian, subject:)

        delivery = NotificationDelivery.create!(
          school: invoice.student.school,
          recipient: guardian,
          channel: :email,
          subject:,
          body: "#{invoice.number} for #{invoice.student.full_name} has a balance of #{invoice.balance} #{invoice.student.school.currency_code} due on #{invoice.due_on}."
        )
        NotificationDeliveryJob.perform_later(delivery)
      end
    end
  end
end
