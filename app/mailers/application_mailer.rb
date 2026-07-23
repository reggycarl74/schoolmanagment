class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "SchoolOS <notifications@example.com>")
  layout "mailer"
end
