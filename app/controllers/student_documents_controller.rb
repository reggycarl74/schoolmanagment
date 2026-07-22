class StudentDocumentsController < ApplicationController
  before_action :require_staff

  def create
    student = accessible_students.find(params[:student_id])
    student.documents.attach(params[:documents])
    redirect_to assessments_student_path(student), notice: "Documents were uploaded."
  end

  def destroy
    attachment = ActiveStorage::Attachment.where(record_type: "Student", record_id: accessible_students.select(:id)).find(params[:id])
    student = attachment.record
    attachment.purge
    redirect_to assessments_student_path(student), notice: "Document was removed."
  end
end
