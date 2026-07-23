class TimetableNotificationService
  def self.created(entry)
    teacher = entry.teacher
    return if teacher.email.blank?

    delivery = NotificationDelivery.create!(
      school: teacher.school,
      recipient: teacher,
      source: entry,
      channel: :email,
      subject: "Timetable updated: #{entry.course_section.subject.name}",
      body: "You are scheduled to teach #{entry.course_section.subject.name} for #{entry.course_section.classroom.name} on #{entry.weekday.humanize}, period #{entry.period}, at #{entry.starts_at.strftime('%H:%M')}."
    )
    NotificationDeliveryJob.perform_later(delivery)
  end
end
