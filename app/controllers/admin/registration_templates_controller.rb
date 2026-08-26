module Admin
  class RegistrationTemplatesController < AdminController
    before_action :require_super_admin
    before_action :registration_template, only: %i[show edit update destroy]

    def index
      @registration_templates = RegistrationTemplate.order(:name, :id)
    end

    def show; end

    def new
      @registration_template = RegistrationTemplate.new
    end

    def create
      @registration_template = RegistrationTemplate.new(registration_template_params)

      if @registration_template.save
        redirect_to admin_registration_templates_path,
                    flash: { success: "Registration template created" }
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if registration_template.update(registration_template_params)
        redirect_to admin_registration_template_path(registration_template),
                    flash: { success: "Registration template updated" }
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      registration_template.destroy!
      redirect_to admin_registration_templates_path,
                  flash: { success: "Registration template deleted" }
    end

  private

    def registration_template
      @registration_template ||= RegistrationTemplate.find(params[:id])
    end

    def registration_template_params
      params.require(:registration_template).permit(
        :name,
        :description,
        :template_generating_service_class,
      )
    end
  end
end
