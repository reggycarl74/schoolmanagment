require "test_helper"

class StudentImportsControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = %w[schools academic_years grade_levels classrooms students enrollments users]

  test "administrator sees class selector and downloads template" do
    sign_in(users(:admin))
    get students_path
    assert_response :success
    assert_select "select[name=classroom_id] option", text: "Grade 4A · 2026/2027"
    get import_template_students_path
    assert_response :success
    assert_equal StudentCsvImport.template, response.body
  end

  test "missing file returns useful error" do
    sign_in(users(:admin))
    post import_students_path, params: { classroom_id: classrooms(:assigned).id }
    assert_redirected_to students_path
    assert_match "Select a CSV file", flash[:alert]
  end

  test "teacher cannot import or download template" do
    sign_in(users(:teacher_user))
    post import_students_path
    assert_redirected_to root_path
    get import_template_students_path
    assert_redirected_to root_path
  end

  test "administrator uploads a CSV into the selected class" do
    sign_in(users(:admin))
    Tempfile.create([ "students", ".csv" ]) do |file|
      file.write("admission_number,first_name,last_name,date_of_birth,gender,admitted_on\nNEW01,New,Student,2015-01-01,undisclosed,2026-08-01\n")
      file.flush
      upload = Rack::Test::UploadedFile.new(file.path, "text/csv")
      assert_difference [ "Student.count", "Enrollment.count" ], 1 do
        post import_students_path, params: { classroom_id: classrooms(:assigned).id, file: upload }
      end
      assert_redirected_to students_path
      assert_match "Imported 1 students into Grade 4A", flash[:notice]
    end
  end

  private

  def sign_in(user)
    post session_path, params: { session: { school_code: user.school.code, email: user.email, password: "Password123!" } }
  end
end
