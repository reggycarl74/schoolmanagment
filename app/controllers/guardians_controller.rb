class GuardiansController < ApplicationController
  before_action :require_administrator_or_registrar
  before_action :set_guardian, only: %i[edit update]
  before_action :load_students, only: %i[new create edit update]

  def index
    @guardians = current_school.guardians.includes(:students).order(:last_name, :first_name)
  end

  def new = @guardian = current_school.guardians.new

  def create
    @guardian = current_school.guardians.new(guardian_params)
    if save_guardian
      redirect_to guardians_path, notice: "Guardian was added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if save_guardian
      redirect_to guardians_path, notice: "Guardian was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_guardian = @guardian = current_school.guardians.find(params[:id])
  def load_students = @students = current_school.students.active.order(:last_name)
  def guardian_params = params.expect(guardian: %i[first_name last_name email phone address])

  def save_guardian
    ActiveRecord::Base.transaction do
      @guardian.update!(guardian_params)
      @guardian.student_guardians.where.not(student_id: params[:student_ids]).destroy_all
      Array(params[:student_ids]).reject(&:blank?).each do |student_id|
        @guardian.student_guardians.find_or_create_by!(student: current_school.students.find(student_id)) { |link| link.relationship = "Guardian" }
      end
    end
    true
  rescue ActiveRecord::RecordInvalid => error
    @guardian.errors.add(:base, error.message) if @guardian.errors.empty?
    false
  end
end
