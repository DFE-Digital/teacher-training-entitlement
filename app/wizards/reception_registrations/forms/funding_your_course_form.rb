module ReceptionRegistrations
  module Forms
    class FundingYourCourseForm < StepForm
      attribute :funding

      validates_presence_of :funding
      validate :validate_funding

      def options
        RegistrationState::VALID_FUNDING_OPTIONS
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
