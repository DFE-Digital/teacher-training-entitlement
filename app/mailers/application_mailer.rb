class ApplicationMailer < Mail::Notify::Mailer
  # We use Gov.uk Notify to send emails, and the `default from:` is ignored
  # default from: "continuing-professional-development@digital.education.gov.uk"
  layout "mailer"
end
