namespace :provider do
  desc "Update provider user emails with subaddressing"
  task :update_user_emails, %i[provider_name email_template] => :environment do |_t, args|
    # Validate arguments
    if args.provider_name.blank?
      puts "Error: Provider name is required"
      puts "Usage: rake provider:update_user_emails['Provider Name','email@domain.com']"
      exit 1
    end

    if args.email_template.blank?
      puts "Error: Email template is required"
      puts "Usage: rake provider:update_user_emails['Provider Name','email@domain.com']"
      exit 1
    end

    Rails.logger.info("Starting email update for provider: #{args.provider_name}")

    # Find the provider by name
    provider = LeadProvider.find_by(name: args.provider_name)
    unless provider
      puts "Error: Provider with name '#{args.provider_name}' not found"
      exit 1
    end

    # Find all users associated with this provider through applications
    users = User.joins(applications: :application_lead_providers)
                .where(application_lead_providers: { lead_provider_id: provider.id })
                .distinct

    puts "Found #{users.count} users for provider '#{provider.name}'"

    if users.count.zero?
      puts "No users found for provider '#{provider.name}'. Nothing to update."
      exit 0
    end

    # Parse the email template to get the base email and domain
    # Expecting format like "tte@ucl.ac.uk" or "tte+1@ucl.ac.uk"
    template_parts = args.email_template.split("@")
    if template_parts.length != 2
      puts "Error: Email template must be in format 'local-part@domain'"
      exit 1
    end

    local_part = template_parts[0]
    domain = template_parts[1]

    # Extract the base part before any + (for subaddressing)
    base_local_part = local_part.split("+").first

    # Update each user's email with a unique counter in the format: base+test{index+1}@domain
    updated_count = 0
    failed_count = 0

    users.each_with_index do |user, index|
      # Generate subaddressed email: base+test{index+1}@domain
      new_email = "#{base_local_part}+test#{index + 1}@#{domain}"

      puts "Updating user #{user.id} (#{user.email}) -> #{new_email}"

      # Update the email
      if user.update!(email: new_email)
        updated_count += 1
      else
        failed_count += 1
        puts "Failed to update user #{user.id}: #{user.errors.full_messages.join(', ')}"
      end
    end

    puts "Successfully updated #{updated_count} email addresses"
    puts "Failed to update #{failed_count} email addresses" if failed_count.positive?
  end
end
