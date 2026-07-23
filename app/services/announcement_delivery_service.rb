class AnnouncementDeliveryService
  def self.call(announcement) = new(announcement).call

  def initialize(announcement)
    @announcement = announcement
    @school = announcement.school
  end

  def call
    recipients.each do |recipient|
      create_delivery(recipient, :email) if @announcement.send_email? && recipient.respond_to?(:email) && recipient.email.present?
      create_delivery(recipient, :sms) if @announcement.send_sms? && recipient.respond_to?(:phone) && recipient.phone.present?
    end
  end

  private

  def recipients
    records = case @announcement.audience
    when "staff" then @school.teachers.where(active: true).to_a + @school.users.where(role: %i[registrar accountant]).to_a
    when "parents" then @school.guardians.where(active: true).to_a
    when "students" then @school.users.where(role: :student, active: true).to_a
    else @school.teachers.where(active: true).to_a + @school.guardians.where(active: true).to_a + @school.users.where(role: %i[registrar accountant student], active: true).to_a
    end
    records.uniq { |record| [ record.class.name, record.id ] }
  end

  def create_delivery(recipient, channel)
    delivery = NotificationDelivery.find_or_create_by!(source: @announcement, recipient: recipient, channel: channel) do |record|
      record.school = @school
      record.subject = @announcement.title
      record.body = @announcement.body
    end
    NotificationDeliveryJob.perform_later(delivery) if delivery.pending?
  end
end
