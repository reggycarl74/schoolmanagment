class GuardiansController < ApplicationController
  before_action :require_administrator_or_registrar
  before_action :set_guardian, only: %i[show edit update invite toggle_portal_access]
  before_action :load_students, only: %i[new create edit update]
  before_action :require_administrator, only: %i[invite toggle_portal_access]

  def index
    @guardians = current_school.guardians.includes(:user, student_guardians: :student).order(:last_name, :first_name)
    if params[:query].present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(params[:query].strip)}%"
      @guardians = @guardians.left_joins(:students).where(
        "guardians.first_name LIKE :query OR guardians.last_name LIKE :query OR guardians.phone LIKE :query OR guardians.alternate_phone LIKE :query OR guardians.email LIKE :query OR students.first_name LIKE :query OR students.last_name LIKE :query",
        query: pattern
      ).distinct
    end
    @guardians = @guardians.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params[:active].present?
    @guardians = case params[:portal]
    when "active" then @guardians.joins(:user).where(users: { active: true })
    when "disabled" then @guardians.joins(:user).where(users: { active: false })
    when "not_invited" then @guardians.left_joins(:user).where(users: { id: nil })
    else @guardians
    end
    @guardians = @guardians.limit(100)
  end

  def show
    @relationships = @guardian.student_guardians.includes(student: [ :invoices, { enrollments: :classroom } ]).order(primary_contact: :desc, created_at: :asc)
    @recent_deliveries = current_school.notification_deliveries.where(recipient: @guardian).order(created_at: :desc).limit(10)
  end

  def new
    @guardian = current_school.guardians.new(preferred_language: "English")
  end

  def create
    @guardian = current_school.guardians.new(guardian_params)
    if save_guardian
      redirect_to guardian_path(@guardian), notice: "Guardian was added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if save_guardian
      redirect_to guardian_path(@guardian), notice: "Guardian was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def invite
    if @guardian.email.blank?
      return redirect_to edit_guardian_path(@guardian), alert: "Add an email address before creating portal access."
    end

    user = @guardian.user || current_school.users.find_or_initialize_by(email: @guardian.email)
    unless user.new_record? || user.guardian == @guardian
      return redirect_to guardian_path(@guardian), alert: "That email already belongs to another user."
    end

    user.assign_attributes(
      first_name: @guardian.first_name,
      last_name: @guardian.last_name,
      role: :parent,
      guardian: @guardian,
      active: true,
      password: SecureRandom.base58(16)
    ) if user.new_record?
    user.active = true
    user.save!
    UserMailer.password_reset(user).deliver_later
    AuditEvent.create!(school: current_school, user: current_user, auditable: @guardian, action: "guardian_portal_invited")
    redirect_to guardian_path(@guardian), notice: "Portal access is active and password setup instructions were queued for #{@guardian.email}."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to guardian_path(@guardian), alert: error.record.errors.full_messages.to_sentence
  end

  def toggle_portal_access
    return redirect_to(guardian_path(@guardian), alert: "This guardian does not have a portal account.") unless @guardian.user

    @guardian.user.update!(active: !@guardian.user.active?)
    action = @guardian.user.active? ? "guardian_portal_enabled" : "guardian_portal_disabled"
    AuditEvent.create!(school: current_school, user: current_user, auditable: @guardian, action: action)
    redirect_to guardian_path(@guardian), notice: "Portal access was #{@guardian.user.active? ? 'enabled' : 'disabled'}."
  end

  private

  def set_guardian
    @guardian = current_school.guardians.includes(:user, student_guardians: :student).find(params[:id])
  end

  def load_students
    @students = current_school.students.active.order(:last_name, :first_name)
    @relationship_by_student_id = @guardian ? @guardian.student_guardians.index_by(&:student_id) : {}
  end

  def guardian_params
    params.require(:guardian).permit(:first_name, :last_name, :email, :phone, :alternate_phone, :address,
      :preferred_language, :preferred_contact_method, :occupation, :active, :private_notes)
  end

  def relationship_params
    values = params.dig(:guardian, :relationships)&.values || []
    values.select { |attributes| ActiveModel::Type::Boolean.new.cast(attributes[:selected]) }
  end

  def save_guardian
    ActiveRecord::Base.transaction do
      @guardian.update!(guardian_params)
      @guardian.user&.update!(active: false) unless @guardian.active?
      submitted_student_ids = relationship_params.filter_map { |attributes| attributes[:student_id].presence&.to_i }
      @guardian.student_guardians.where.not(student_id: submitted_student_ids).destroy_all

      relationship_params.each do |attributes|
        student_id = attributes[:student_id].presence
        next unless student_id

        student = current_school.students.find(student_id)
        relationship = @guardian.student_guardians.find_or_initialize_by(student: student)
        relationship.assign_attributes(attributes.permit(
          :relationship, :primary_contact, :pickup_authorized, :emergency_contact, :emergency_priority,
          :lives_with_student, :financially_responsible, :academic_access, :attendance_access,
          :billing_access, :contact_allowed, :custody_restrictions, :pickup_notes
        ))
        relationship.save!
      end
    end
    true
  rescue ActiveRecord::RecordInvalid => error
    @guardian.errors.add(:base, error.record.errors.full_messages.to_sentence) if @guardian.errors.empty?
    false
  rescue ActiveRecord::RecordNotFound
    @guardian.errors.add(:base, "One or more selected students are invalid")
    false
  end
end
