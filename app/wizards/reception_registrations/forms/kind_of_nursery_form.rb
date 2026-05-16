module ReceptionRegistrations
  module Forms
    class KindOfNurseryForm < StepForm
      attribute :kind_of_nursery

      validates :kind_of_nursery, presence: true, inclusion: { in: RegistrationState::KIND_OF_NURSERY_OPTIONS }

      def options
        RegistrationState::KIND_OF_NURSERY_OPTIONS
      end

      def self.permitted_params
        %i[kind_of_nursery]
      end
    end
  end
end
