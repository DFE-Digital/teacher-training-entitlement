module Admin
  class RegistrationJourneysController < AdminController
    before_action :require_super_admin, except: %i[index show]
    before_action :registration_journey, only: %i[show edit update destroy update_registration_steps]

    def index
      @registration_journeys = RegistrationJourney.order(:id).includes(:registration_steps)
    end

    def show
      @registration_steps = registration_journey.registration_steps
      @registration_journey_graph = RegistrationJourneyGraph.new(registration_journey)
    end

    def new
      @registration_journey = RegistrationJourney.new
    end

    def create
      @registration_journey = RegistrationJourney.new(registration_journey_params)

      if @registration_journey.save
        redirect_to admin_registration_journey_path(@registration_journey), flash: { success: "Registration journey created" }
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if registration_journey.update(registration_journey_params)
        redirect_to admin_registration_journey_path(registration_journey), flash: { success: "Registration journey updated" }
      else
        render :edit, status: :unprocessable_content
      end
    end

    def update_registration_steps
      update_registration_steps!

      redirect_to admin_registration_journey_path(registration_journey), flash: { success: "Registration steps updated" }
    rescue ActiveRecord::RecordInvalid
      @registration_steps = registration_journey.registration_steps
      @registration_journey_graph = RegistrationJourneyGraph.new(registration_journey)
      render :show, status: :unprocessable_content
    end

    def destroy
      registration_journey.destroy!
      redirect_to admin_registration_journeys_path, flash: { success: "Registration journey deleted" }
    end

  private

    def registration_journey
      @registration_journey ||= RegistrationJourney.find(params[:id])
    end

    def registration_journey_params
      params.require(:registration_journey).permit(:name, :slug, :course_id)
    end

    def registration_steps_params
      params.fetch(:registration_steps, {}).permit!.to_h
    end

    def update_registration_steps!
      ActiveRecord::Base.transaction do
        registration_steps_params.each do |id, step_params|
          registration_journey.registration_steps.find(id).update!(
            step_params.slice("name", "order"),
          )
        end
      end
    end
  end
end
