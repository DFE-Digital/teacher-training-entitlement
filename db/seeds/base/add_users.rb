otp_testing_code = "00000"

AdminUser.find_or_create_by!(email: "bianca.napoleonov@education.gov.uk") do |admin|
  admin.assign_attributes(
    full_name: "Bianca NAPOLEONOV",
    otp_hash: otp_testing_code,
    otp_expires_at: "3000-01-01 00:00:00.000000000 +0000",
    super_admin: false,
  )
end

# Create super admin user
AdminUser.find_or_create_by!(email: "superadmin@example.com") do |admin|
  admin.assign_attributes(
    full_name: "example super admin",
    otp_hash: otp_testing_code,
    otp_expires_at: "3000-01-01 00:00:00.000000000 +0000",
    super_admin:
    true,
  )
end
