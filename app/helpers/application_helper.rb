module ApplicationHelper
  CURRENCY_UNITS = { "USD" => "$", "EUR" => "€", "GBP" => "£", "GHS" => "GH₵", "NGN" => "₦", "ZAR" => "R", "KES" => "KSh" }.freeze

  def money(amount)
    number_to_currency(amount, unit: CURRENCY_UNITS.fetch(current_school.currency_code, "#{current_school.currency_code} "))
  end
end
