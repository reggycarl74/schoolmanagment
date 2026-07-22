require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "signup page shows school and registration code fields" do
    get new_registration_path

    assert_response :success
    assert_select "input[name='user[school_code]']"
    assert_select "input[name='user[registration_code]']"
  end

  test "registration code creates an active administrator immediately" do
    assert_difference("User.count", 1) do
      post registration_path, params: registration_params(
        email: "new.admin@example.test",
        registration_code: "checkers"
      )
    end

    user = User.find_by!(email: "new.admin@example.test")
    assert user.administrator?
    assert user.active?
    assert_redirected_to new_session_path

    post session_path, params: login_params(user.email)
    assert_redirected_to root_path
  end

  test "standard registration waits for administrator approval" do
    post registration_path, params: registration_params(email: "pending.teacher@example.test")

    user = User.find_by!(email: "pending.teacher@example.test")
    assert user.teacher?
    assert_not user.active?

    post session_path, params: login_params(user.email)
    assert_response :unprocessable_entity
    assert_includes response.body, "waiting for administrator approval"
  end

  test "administrator can approve a pending registration" do
    post registration_path, params: registration_params(email: "approve.me@example.test")
    pending_user = User.find_by!(email: "approve.me@example.test")

    post session_path, params: {
      session: { school_code: "DEMO", email: users(:admin).email, password: "Password123!" }
    }
    patch approve_admin_user_path(pending_user)

    assert_redirected_to admin_users_path
    assert pending_user.reload.active?
  end

  private

  def registration_params(email:, registration_code: "")
    {
      user: {
        school_code: "DEMO",
        registration_code:,
        first_name: "New",
        last_name: "User",
        email:,
        role: "teacher",
        password: "SecurePass123!",
        password_confirmation: "SecurePass123!"
      }
    }
  end

  def login_params(email)
    { session: { school_code: "DEMO", email:, password: "SecurePass123!" } }
  end
end
