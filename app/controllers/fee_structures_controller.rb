class FeeStructuresController < ApplicationController
  before_action :require_finance

  def index
    @fee_structures = current_school.fee_structures.includes(:academic_year, :invoices).order(due_on: :desc)
  end

  def new
    @fee_structure = current_school.fee_structures.new
    @academic_years = current_school.academic_years.order(starts_on: :desc)
  end

  def create
    @fee_structure = current_school.fee_structures.new(fee_params)
    if @fee_structure.save
      redirect_to fee_structures_path, notice: "Fee structure was created."
    else
      @academic_years = current_school.academic_years.order(starts_on: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def fee_params
    params.expect(fee_structure: %i[academic_year_id name amount due_on frequency starts_on ends_on active])
  end
end
