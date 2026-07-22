require "test_helper"

class TeacherStudentAccessTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: {
      session: { school_code: "DEMO", email: "teacher@example.test", password: "Password123!" }
    }
  end

  test "teacher sees only students in assigned classes" do
    get students_path

    assert_response :success
    assert_includes response.body, "Visible Student"
    assert_not_includes response.body, "Hidden Student"
  end

  test "teacher cannot open another class student's assessments" do
    get assessments_student_path(students(:hidden))

    assert_response :not_found
  end
end
