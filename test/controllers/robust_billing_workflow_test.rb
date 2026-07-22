require "test_helper"

class RobustBillingWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in(users(:admin))
    @fee = FeeStructure.create!(school: schools(:demo), academic_year: academic_years(:current), name: "Robust billing fee", amount: 600, due_on: Date.new(2026, 9, 1))
    @invoice = Invoice.create!(student: students(:visible), fee_structure: @fee, amount: 600, due_on: @fee.due_on)
    @invoice.line_items.create!(description: "Tuition", category: :tuition, quantity: 1, unit_amount: 600)
  end

  test "invoice page renders line items payment plans and adjustments" do
    get invoice_path(@invoice)

    assert_response :success
    assert_includes response.body, @invoice.number
    assert_includes response.body, "Payment plan"
    assert_includes response.body, "Approved adjustment"
  end

  test "line items recalculate invoice total" do
    post invoice_invoice_line_items_path(@invoice), params: {
      invoice_line_item: { description: "Books", category: "books", quantity: 2, unit_amount: 25 }
    }

    assert_redirected_to invoice_path(@invoice)
    assert_equal 650.to_d, @invoice.reload.amount
    assert AuditEvent.exists?(auditable_type: "InvoiceLineItem", action: "invoice_line_item_added")
  end

  test "partial payment creates numbered printable receipt" do
    post invoice_payments_path(@invoice), params: {
      payment: { amount: 200, paid_on: Date.current, reference: "TEST-PAY-001", payment_method: "bank_transfer" }
    }

    payment = @invoice.payments.find_by!(reference: "TEST-PAY-001")
    assert_match(/\ARCT-\d{4}-[A-F0-9]{8}\z/, payment.receipt_number)
    assert_equal users(:admin), payment.recorded_by
    assert @invoice.reload.partially_paid?
    assert_redirected_to invoice_payment_path(@invoice, payment)

    follow_redirect!
    assert_response :success
    assert_includes response.body, "Print receipt"
  end

  test "payment cannot exceed outstanding balance" do
    assert_no_difference("Payment.count") do
      post invoice_payments_path(@invoice), params: {
        payment: { amount: 601, paid_on: Date.current, reference: "TEST-OVERPAY", payment_method: "cash" }
      }
    end

    assert_redirected_to invoice_path(@invoice)
    assert_match(/cannot exceed/, flash[:alert])
  end

  test "administrator reverses payment without deleting it" do
    payment = @invoice.payments.create!(amount: 100, paid_on: Date.current, reference: "TEST-REVERSE", payment_method: :cash, recorded_by: users(:admin))

    patch reverse_invoice_payment_path(@invoice, payment), params: { reversal_reason: "Entered twice" }

    assert_redirected_to invoice_path(@invoice)
    assert payment.reload.reversed?
    assert_equal "Entered twice", payment.reversal_reason
    assert_equal 0, @invoice.reload.paid_amount
    assert AuditEvent.exists?(auditable: payment, action: "payment_reversed")
  end

  test "approved scholarship reduces invoice balance" do
    assert_difference("BillingAdjustment.count", 1) do
      post invoice_billing_adjustments_path(@invoice), params: {
        billing_adjustment: { kind: "scholarship", amount: 75, reason: "Merit award" }
      }
    end

    assert_equal 525.to_d, @invoice.reload.balance
    adjustment = @invoice.billing_adjustments.last
    assert_equal users(:admin), adjustment.approved_by
  end

  test "installment plan cannot exceed invoice total" do
    post invoice_payment_installments_path(@invoice), params: { payment_installment: { name: "First", amount: 400, due_on: Date.current + 1.month } }
    assert_redirected_to invoice_path(@invoice)

    assert_no_difference("PaymentInstallment.count") do
      post invoice_payment_installments_path(@invoice), params: { payment_installment: { name: "Second", amount: 300, due_on: Date.current + 2.months } }
    end
    assert_match(/exceed/, flash[:alert])
  end

  test "student ledger and collection CSV are available" do
    get student_billing_statement_path(students(:visible))
    assert_response :success
    assert_includes response.body, @invoice.number

    get financial_report_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body, "receipt,date,student,invoice"
  end

  private

  def sign_in(user)
    post session_path, params: { session: { school_code: user.school.code, email: user.email, password: "Password123!" } }
  end
end
