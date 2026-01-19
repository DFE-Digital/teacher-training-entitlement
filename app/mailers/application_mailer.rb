class ApplicationMailer < Mail::Notify::Mailer
  default from: "teacher-training-entitlement@digital.education.gov.uk"
  layout "mailer"
end
