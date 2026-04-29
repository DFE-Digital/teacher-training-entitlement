otp_testing_code = "00000"

# Create admin user
AdminUser.find_or_create_by!(email: "admin@example.com") do |admin|
  admin.assign_attributes(
    full_name: "example admin",
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

User.find_or_create_by!(email: "jerome.riga@education.gov.uk") do |user|
  user.assign_attributes(
    full_name: "Jerome Riga",
    trn: "3013406",
    trn_verified: true,
  )
end

User.find_or_create_by!(email: "gurmukh.bhurjee@education.gov.uk") do |user|
  user.assign_attributes(
    full_name: "Gurmukh BHURJEE",
    trn: "3013407",
    trn_verified: true,
  )
end

User.find_or_create_by!(email: "toby.privett@education.gov.uk") do |user|
  user.assign_attributes(
    full_name: "Toby Privett",
    trn: "3013362",
    trn_verified: true,
  )
end

User.find_or_create_by!(email: "ben.keeping@education.gov.uk") do |user|
  user.assign_attributes(
    full_name: "Ben Keeping",
    trn: "3013408",
    trn_verified: true,
  )
end

User.find_or_create_by!(email: "alice@example.com") do |user|
  user.assign_attributes(
    full_name: "Alice",
    trn: "alice",
    trn_verified: true,
  )
end

User.find_or_create_by!(email: "bob@example.com") do |user|
  user.assign_attributes(
    full_name: "Charlie",
    trn: "bob",
    trn_verified: true,
  )
end

User.find_or_create_by!(email: "charlie@example.com") do |user|
  user.assign_attributes(
    full_name: "Charlie",
    trn: "charlie",
    trn_verified: true,
  )
end

User.find_or_create_by!(email: "dave@example.com") do |user|
  user.assign_attributes(
    full_name: "Dave",
    trn: "dave",
    trn_verified: true,
  )
end

User.find_or_create_by!(email: "eve@example.com") do |user|
  user.assign_attributes(
    full_name: "Eve",
    trn: "eve",
    trn_verified: true,
  )
end
