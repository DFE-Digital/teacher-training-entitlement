module Admin
  class RegistrationStepDuplicationsController < AdminController
    before_action :require_super_admin

    def create
      duplicate_registration_step!

      redirect_to admin_registration_journey_path(registration_journey),
                  flash: { success: "Registration step duplicated" }
    end

  private

    def registration_journey
      @registration_journey ||= RegistrationJourney.find(params[:registration_journey_id])
    end

    def registration_step
      @registration_step ||= registration_journey.registration_steps.find(params[:registration_step_id])
    end

    def duplicate_registration_step!
      RegistrationStep.transaction do
        registration_steps = registration_journey.registration_steps.to_a
        source_index = registration_steps.index(registration_step)
        duplicate = registration_step.dup
        duplicate.name = unique_copy_of(registration_step.name, registration_steps.map(&:name), separator: " ")
        duplicate.slug = unique_copy_of(registration_step.slug, registration_steps.map(&:slug), separator: "-")
        duplicate.save!

        registration_steps.insert(source_index + 1, duplicate)
        registration_steps.each.with_index(1) do |step, position|
          step.update!(order: position)
        end
      end
    end

    def unique_copy_of(value, existing_values, separator:)
      base = "#{value}#{separator}copy"
      return base unless base.in?(existing_values)

      suffix = 2
      suffix += 1 while "#{base}#{separator}#{suffix}".in?(existing_values)
      "#{base}#{separator}#{suffix}"
    end
  end
end
