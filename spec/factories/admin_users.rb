FactoryBot.define do
  factory :admin, class: "AdminUser" do
    full_name { "John Doe" }
    sequence(:email) { |n| "admin#{n}@example.com" }
  end

  factory :super_admin, class: "AdminUser" do
    full_name { "Super Doe" }
    sequence(:email) { |n| "superadmin#{n}@example.com" }
    otp_expires_at { 1.hour.from_now }
    super_admin { true }
  end
end
