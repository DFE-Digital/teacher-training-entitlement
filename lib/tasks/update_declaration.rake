namespace :update_declaration do
  desc "Clawback a declaration"
  task :clawback, %i[declaration_ecf_id] => :versioned_environment do |_t, args|
    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)
    declaration = Declaration.find_by(ecf_id: args.declaration_ecf_id)
    raise "Declaration not found: #{args.declaration_ecf_id}" unless declaration

    service = Declarations::Clawback.new(declaration:)

    service.call

    if service.errors.blank?
      logger.info("Declaration #{args.declaration_ecf_id} set to state #{declaration.state}")
    else
      logger.error(service.errors.full_messages.to_sentence)
    end
  end

  desc "Void a declaration"
  task :void, %i[declaration_ecf_id] => :versioned_environment do |_t, args|
    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)
    declaration = Declaration.find_by(ecf_id: args.declaration_ecf_id)
    raise "Declaration not found: #{args.declaration_ecf_id}" unless declaration

    service = Declarations::Void.new(declaration:)

    service.call

    if service.errors.blank?
      logger.info("Declaration #{args.declaration_ecf_id} set to state #{declaration.state}")
    else
      logger.error(service.errors.full_messages.to_sentence)
    end
  end
end
