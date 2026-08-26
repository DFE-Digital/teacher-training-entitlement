module Forms
  class RadioButtonsStepForm < RegistrationStepForm
    validates :step_answer, presence: { message: "Select an answer" }
  end
end
