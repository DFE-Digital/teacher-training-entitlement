{
  "registration-reopening-1@example.com" => "Ada Lovelace",
  "registration-reopening-2@example.com" => "Grace Hopper",
  "registration-reopening-3@example.com" => "Mary Somerville",
}.each do |email, full_name|
  EmailUpdateSubscription.find_or_create_by!(email:, status: EmailUpdateSubscription::NPD_REGISTRATION_OPEN) do |subscription|
    subscription.full_name = full_name
  end
end
