class Current < ActiveSupport::CurrentAttributes
  attribute :user

  delegate :school, to: :user, allow_nil: true
end
