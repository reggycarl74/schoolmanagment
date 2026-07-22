require "test_helper"

class InvoicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: {
      session: { school_code: "DEMO", email: users(:admin).email, password: "Password123!" }
    }
    @fee = FeeStructure.create!(
      school: schools(:demo),
      academic_year: academic_years(:current),
      name: "Bulk tuition",
      amount: 525,
      due_on: Date.new(2026, 9, 1)
    )
  end

  test "new invoice page renders student checkboxes" do
    get new_invoice_path

    assert_response :success
    assert_select "input[type='checkbox'][name='invoice[student_ids][]']", minimum: 2
    assert_select "input[type='checkbox'][data-checkbox-selection-target='all']", count: 1
  end

  test "creates invoices for multiple selected students" do
    selected_students = [ students(:visible), students(:hidden) ]

    assert_difference("Invoice.count", 2) do
      post invoices_path, params: {
        invoice: { fee_structure_id: @fee.id, student_ids: selected_students.map(&:id) }
      }
    end

    assert_redirected_to invoices_path
    selected_students.each do |student|
      invoice = Invoice.find_by!(student:, fee_structure: @fee)
      assert_equal @fee.amount, invoice.amount
      assert_equal @fee.due_on, invoice.due_on
    end
  end

  test "skips invoices that already exist" do
    Invoice.create!(student: students(:visible), fee_structure: @fee, amount: @fee.amount, due_on: @fee.due_on)

    assert_no_difference("Invoice.count") do
      post invoices_path, params: {
        invoice: { fee_structure_id: @fee.id, student_ids: [ students(:visible).id ] }
      }
    end

    assert_redirected_to invoices_path
    assert_equal "Generated 0 invoices. Skipped 1 existing invoice.", flash[:notice]
  end

  test "requires at least one selected student" do
    post invoices_path, params: { invoice: { fee_structure_id: @fee.id, student_ids: [] } }

    assert_response :unprocessable_entity
    assert_includes response.body, "Select at least one student"
  end
end
