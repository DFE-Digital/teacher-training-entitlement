namespace :api_test do
  desc "Test the Void Declaration endpoint"
  # Call the void declaration api endpoint using any declaration
  # or optionally with a specific declaration id
  # Usage when using any declaration:
  #    rake api_test:void_declaration
  #
  # Usage when using a specific declaration
  #    rake api_test:void_declaration\[279]
  #
  task :void_declaration, %i[declaration_id] => :environment do |_t, args|
    declaration = if args[:declaration_id].present?
                    Declaration.find_by_id(args[:declaration_id])
                  end

    ::APITests::VoidDeclaration.new(declaration:).call
  end
end
