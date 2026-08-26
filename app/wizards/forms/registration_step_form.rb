module Forms
  class RegistrationStepForm
    include DfE::Wizard::Step

    attribute :step_answer

    def self.permitted_params
      %i[step_answer]
    end
  end
end
