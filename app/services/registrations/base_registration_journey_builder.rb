module Registrations
  class BaseRegistrationJourneyBuilder
  protected

    # Builds a step and configures any content, custom rendering, or services.
    def create_step!(
      step_class:,
      answers: [],
      previous_step_id: nil,
      config: {},
      texts: [],
      html_partial: nil,
      view_component: nil,
      services: [],
      **attributes
    )
      RegistrationStep.transaction do
        step = Steps::Create.new(
          registration_journey:,
          step_class:,
          answers:,
          previous_step_id:,
          config:,
          **attributes,
        ).call

        texts.each { |text_attributes| step.add_text!(**text_attributes) }
        step.set_html_partial!(partial_name: html_partial) if html_partial.present?
        step.set_view_component!(component_class_name: view_component) if view_component.present?
        services.each { |service_attributes| step.add_service!(**service_attributes) }

        step
      end
    end
  end
end
