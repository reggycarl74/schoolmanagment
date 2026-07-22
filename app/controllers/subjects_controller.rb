class SubjectsController < ResourceIndexController
  before_action :require_administrator, only: %i[new create]
  def index
    @records = current_school.subjects.order(:name).limit(50)
  end

  def new
    @subject = current_school.subjects.new
  end

  def create
    @subject = current_school.subjects.new(subject_params)

    if @subject.save
      redirect_to subjects_path, notice: "Subject was added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def subject_params
    params.expect(subject: %i[name code])
  end
end
