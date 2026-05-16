module ReceptionRegistrations
  module Forms
    class StepForm
      include DfE::Wizard::Step

      delegate :state_store, to: :wizard
    end
  end
end
