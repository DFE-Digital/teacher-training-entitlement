otp_testing_code = "00000"

# Create admin user
Admin.find_or_create_by!(
  email: "admin@example.com",
  full_name: "example admin",
  otp_hash: otp_testing_code,
  otp_expires_at: "3000-01-01 00:00:00.000000000 +0000",
  super_admin: false,
)

# Create admin user
Admin.find_or_create_by!(
  email: "superadmin@example.com",
  full_name: "example super admin",
  otp_hash: otp_testing_code,
  otp_expires_at: "3000-01-01 00:00:00.000000000 +0000",
  super_admin: true,
)

User.find_or_create_by!(email: "jerome.riga@education.gov.uk") do |user|
  user.assign_attributes(
    full_name: "Jerome Riga",
    trn: "0000001",
  )
end

User.find_or_create_by!(email: "Gurmukh.BHURJEE@education.gov.uk") do |user|
  user.assign_attributes(
    full_name: "Gurmukh BHURJEE",
    trn: "0000002",
  )
end

User.find_or_create_by!(email: "toby.privett@education.gov.uk") do |user|
  user.assign_attributes(
    full_name: "Toby Privett",
    trn: "0000003",
  )
end
