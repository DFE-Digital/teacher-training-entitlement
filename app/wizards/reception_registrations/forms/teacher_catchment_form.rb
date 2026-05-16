module ReceptionRegistrations
  module Forms
    class TeacherCatchmentForm < StepForm
      attribute :teacher_catchment, :string

      validates_presence_of :teacher_catchment

      def self.permitted_params
        %i[teacher_catchment]
      end
    end
  end
end
