require "test_helper"

class GuardianTest < ActiveSupport::TestCase
  test "email contact requires an email address" do
    guardian = schools(:demo).guardians.new(first_name: "Akos", last_name: "Parent", phone: "+233 20 333 3333", preferred_contact_method: :email)

    assert_not guardian.valid?
    assert_includes guardian.errors[:email], "is required when email is the preferred contact method"
  end

  test "phone contact can be saved without an email address" do
    guardian = schools(:demo).guardians.new(first_name: "Akos", last_name: "Parent", phone: "+233 20 333 3333", preferred_contact_method: :phone)

    assert guardian.valid?
  end
end
