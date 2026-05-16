module ReceptionRegistrations
  module Forms
    class CourseStartDateForm < StepForm
      attribute :confirmation, :string

      validates_presence_of :confirmation

      def self.permitted_params
        %i[confirmation]
      end
    end
  end
end
