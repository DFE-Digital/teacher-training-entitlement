module Helpers
  module Institution
  private

    # TODO: Consider adding `delegate :name, :address, :in_england?, to: :institution, prefix: :employer`
    # to Application model to simplify employer-related method access.

    def institution(source: wizard.store["institution_identifier"], application: nil)
      return @institution if @institution
      return nil if source.nil?

      application = application.nil? ? query_store : application
      institutionable = ::Institution.find_institutionable_by_identifier(source)

      return nil unless institutionable
      return nil unless valid_for_application?(institutionable, application)

      @institution = institutionable
    end

  private

    def valid_for_application?(institutionable, application)
      case institutionable
      when PrivateChildcareProvider
        application.works_in_childcare?
      when School, LocalAuthority
        application.works_in_childcare? || application.works_in_school?
      else
        false
      end
    end
  end
end
