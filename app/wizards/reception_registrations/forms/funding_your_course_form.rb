module ReceptionRegistrations
  module Forms
    class FundingYourCourseForm < StepForm
      attribute :funding

      validates_presence_of :funding
      validate :validate_funding

      def options
        if state_store["works_in_school"] && state_store.inside_catchment?
          RegistrationState::VALID_FUNDING_OPTIONS - [RegistrationState::EMPLOYER]
        else
          RegistrationState::VALID_FUNDING_OPTIONS - [RegistrationState::TRUST, RegistrationState::EMPLOYER]
        end
      end

      def self.permitted_params
        %i[funding]
      end

    private

      def validate_funding
        if funding.present? && !options.include?(funding)
          errors.add(:funding, :inclusion)
        end
      end
    end
  end
end
