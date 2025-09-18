class ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.application.credentials.email&.dig(:from) || "noreply@abyzma.com" }
  layout "mailer"
end
