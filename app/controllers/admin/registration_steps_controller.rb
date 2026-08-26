module Admin
  class RegistrationStepsController < AdminController
    before_action :require_super_admin
    before_action :registration_journey
    before_action :registration_step, only: %i[edit update destroy move_up move_down]

    def index
      @pagy, @registration_steps = pagy(registration_journey.registration_steps)
    end

    def new
      @registration_step = registration_journey.registration_steps.new(config: {})
    end

    def create
      selected_after_step = after_step
      @registration_step = registration_journey.registration_steps.new(registration_step_params)
      @registration_step.order = order_after_step(selected_after_step)

      if @registration_step.save
        resequence_registration_steps(selected_after_step)
        redirect_to edit_admin_registration_journey_registration_step_path(registration_journey, registration_step), flash: { success: "Registration step created" }
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if registration_step.update(registration_step_params)
        redirect_to edit_admin_registration_journey_registration_step_path(registration_journey, registration_step), flash: { success: "Registration step updated" }
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      registration_step.destroy!
      redirect_to admin_registration_journey_path(registration_journey), flash: { success: "Registration step deleted" }
    end

    def move_up
      move_registration_step_by(-1)
    end

    def move_down
      move_registration_step_by(1)
    end

  private

    def registration_journey
      @registration_journey ||= RegistrationJourney.find(params[:registration_journey_id])
    end

    def registration_step
      @registration_step ||= registration_journey.registration_steps.find(params[:id])
    end

    def registration_step_params
      params.require(:registration_step).permit(
        :name,
        :slug,
        :type,
        :answer_key,
        :order,
        :previous_step_id,
        :branch_join_step_id,
        :after_step_id,
        :redirect_path,
        :redirect_state_store_key,
        :funding_eligibility_service_class,
      )
    end

    def order_after_step(after_step)
      return registration_journey.registration_steps.maximum(:order).to_i + 1 if after_step.blank?

      after_step.order.to_i + 1
    end

    def after_step
      @after_step ||= registration_journey.registration_steps.find_by(id: registration_step_params[:after_step_id])
    end

    def resequence_registration_steps(after_step = nil)
      ordered_registration_steps(after_step).each.with_index(1) do |registration_step, position|
        registration_step.update!(order: position)
      end
    end

    def ordered_registration_steps(after_step)
      registration_steps = registration_journey.registration_steps.reload.to_a
      return registration_steps if after_step.blank?

      registration_steps_without_new_step = registration_steps.excluding(registration_step)
      after_step_index = registration_steps_without_new_step.index { |registration_step| registration_step.id == after_step.id }

      registration_steps_without_new_step.insert(after_step_index + 1, registration_step)
    end

    def move_registration_step_by(offset)
      order_groups = RegistrationJourneyGraph.new(registration_journey).order_groups
      current_index = order_groups.index { |group| group.include?(registration_step) }
      target_index = current_index + offset if current_index
      target_group = order_groups[target_index] if target_index&.between?(0, order_groups.size - 1)

      if target_group
        move_order_group(order_groups, current_index, target_index)
        flash[:success] = "Registration step group moved"
      end

      redirect_to admin_registration_journey_path(registration_journey)
    end

    def move_order_group(order_groups, current_index, target_index)
      RegistrationStep.transaction do
        group = order_groups.delete_at(current_index)
        order_groups.insert(target_index, group)

        order_groups.flatten.each.with_index(1) do |step, position|
          step.update!(order: position)
        end
      end
    end
  end
end
