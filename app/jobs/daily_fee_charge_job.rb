class DailyFeeChargeJob < ApplicationJob
  queue_as :default

  def perform
    School.find_each do |school|
      Time.use_zone(school.time_zone) { generate_for(school, Time.zone.today) }
    end
  end

  private

  def generate_for(school, charge_date)
    school.fee_structures.daily.where(active: true).includes(:academic_year).find_each do |fee|
      next unless fee.chargeable_on?(charge_date)

      eligible_students(school, fee).find_each do |student|
        create_charge(student, fee, charge_date)
      end
    end
  end

  def eligible_students(school, fee)
    school.students.active.joins(enrollments: :classroom)
      .where(enrollments: { status: Enrollment.statuses[:enrolled] })
      .where(classrooms: { academic_year_id: fee.academic_year_id })
      .distinct
  end

  def create_charge(student, fee, charge_date)
    invoice = Invoice.find_or_initialize_by(student:, fee_structure: fee, charge_on: charge_date)
    return if invoice.persisted?

    Invoice.transaction do
      invoice.update!(amount: fee.amount, due_on: charge_date, issued_on: charge_date)
      invoice.line_items.create!(
        description: "#{fee.name} — #{charge_date.to_fs(:long)}",
        category: :other,
        quantity: 1,
        unit_amount: fee.amount
      )
    end
  rescue ActiveRecord::RecordNotUnique
    # Another worker already generated this student's charge for the date.
  end
end
