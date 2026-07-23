require "test_helper"

class GuardiansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @school = schools(:demo)
    @student = students(:visible)
    sign_in(users(:admin))
  end

  test "administrator creates a guardian with child-specific permissions" do
    assert_difference([ "Guardian.count", "StudentGuardian.count" ], 1) do
      post guardians_path, params: {
        guardian: {
          first_name: "Ama",
          last_name: "Mensah",
          email: "ama.guardian@example.test",
          phone: "+233 20 000 0000",
          preferred_contact_method: "whatsapp",
          relationships: {
            @student.id.to_s => {
              selected: "1",
              student_id: @student.id,
              relationship: "Mother",
              primary_contact: "1",
              pickup_authorized: "0",
              emergency_contact: "1",
              billing_access: "1",
              academic_access: "1",
              attendance_access: "0",
              contact_allowed: "1"
            }
          }
        }
      }
    end

    guardian = @school.guardians.find_by!(email: "ama.guardian@example.test")
    relationship = guardian.student_guardians.find_by!(student: @student)
    assert_equal "Mother", relationship.relationship
    assert relationship.primary_contact?
    assert relationship.emergency_contact?
    assert relationship.billing_access?
    assert_not relationship.pickup_authorized?
    assert_redirected_to guardian_path(guardian)
  end

  test "guardian search includes a linked student's name" do
    guardian = @school.guardians.create!(first_name: "Kojo", last_name: "Parent", phone: "+233 20 111 1111", preferred_contact_method: :phone)
    guardian.student_guardians.create!(student: @student, relationship: "Father")

    get guardians_path(query: @student.first_name)

    assert_response :success
    assert_includes response.body, guardian.full_name
  end

  test "registrar cannot manage guardian portal access" do
    delete session_path
    registrar = @school.users.create!(first_name: "Test", last_name: "Registrar", email: "registrar.guardian-test@example.test", password: "Password123!", role: :registrar, active: true)
    sign_in(registrar)
    guardian = @school.guardians.create!(first_name: "Kofi", last_name: "Parent", email: "kofi.parent@example.test", phone: "+233 20 222 2222", preferred_contact_method: :email)

    post invite_guardian_path(guardian)

    assert_redirected_to root_path
    assert_nil guardian.reload.user
  end

  private

  def sign_in(user)
    post session_path, params: { session: { school_code: user.school.code, email: user.email, password: "Password123!" } }
  end
end
