require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "administrator can view users and password form" do
    sign_in_as(users(:admin))

    get admin_users_path
    assert_response :success
    assert_select "a", text: "Change password"

    get edit_admin_user_path(users(:teacher_user))
    assert_response :success
    assert_select "form input[name='user[password]']"
    assert_select "form input[name='user[password_confirmation]']"
  end

  test "administrator can change another user's password" do
    sign_in_as(users(:admin))
    patch admin_user_path(users(:teacher_user)), params: {
      user: { password: "NewTeacher456!", password_confirmation: "NewTeacher456!" }
    }

    assert_redirected_to admin_users_path
    assert users(:teacher_user).reload.authenticate("NewTeacher456!")
  end

  test "teacher cannot manage user passwords" do
    sign_in_as(users(:teacher_user))
    get admin_users_path

    assert_redirected_to root_path
  end

  test "password confirmation must match" do
    sign_in_as(users(:admin))
    patch admin_user_path(users(:teacher_user)), params: {
      user: { password: "NewTeacher456!", password_confirmation: "Different456!" }
    }

    assert_response :unprocessable_entity
    assert_not users(:teacher_user).reload.authenticate("NewTeacher456!")
  end

  private

  def sign_in_as(user)
    post session_path, params: {
      session: { school_code: user.school.code, email: user.email, password: "Password123!" }
    }
  end
end
