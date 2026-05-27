otp_testing_code = "00000"

AdminUser.find_or_create_by!(email: "Bianca.NAPOLEONOV@education.gov.uk") do |admin|
  admin.assign_attributes(
    full_name: "example super admin",
    otp_hash: otp_testing_code,
    otp_expires_at: "3000-01-01 00:00:00.000000000 +0000",
    super_admin: false,
  )
end
