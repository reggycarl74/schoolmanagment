class TimetableReminderJob < ApplicationJob
  queue_as :default

  def perform
    School.find_each do |school|
      Time.use_zone(school.time_zone) { remind_school(school) }
    end
  end

  private

  def remind_school(school)
    now = Time.zone.now
    entries = TimetableEntry.joins(:teacher, course_section: :classroom)
      .where(classrooms: { school_id: school.id }, weekday: now.wday)
      .includes(:teacher, course_section: %i[classroom subject])

    entries.each do |entry|
      minutes_until = (entry.starts_at.hour * 60 + entry.starts_at.min) - (now.hour * 60 + now.min)
      next unless minutes_until == 10 && entry.teacher.phone.present?
      next if NotificationDelivery.exists?(source: entry, recipient: entry.teacher, channel: :sms, subject: reminder_subject(entry, now.to_date))

      delivery = NotificationDelivery.create!(
        school: school,
        recipient: entry.teacher,
        source: entry,
        channel: :sms,
        subject: reminder_subject(entry, now.to_date),
        body: "Reminder: #{entry.course_section.subject.name} with #{entry.course_section.classroom.name} starts in 10 minutes at #{entry.starts_at.strftime('%H:%M')}#{entry.room.present? ? " in #{entry.room}" : ''}."
      )
      NotificationDeliveryJob.perform_later(delivery)
    end
  end

  def reminder_subject(entry, date)
    "Timetable reminder #{entry.id} #{date}"
  end
end
