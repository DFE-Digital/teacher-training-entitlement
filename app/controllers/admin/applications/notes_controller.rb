# frozen_string_literal: true

module Admin
  module Applications
    class NotesController < AdminController
      before_action :set_application

      def edit
        @return_path = admin_application_path(@application)
      end

      def update
        if @application.update(notes_params)
          flash[:success] = "Notes updated."
          redirect_to admin_application_path(@application)
        else
          render :edit
        end
      end

    private

      def notes_params
        params.require(:application).permit(:notes)
      end

      def set_application
        @application = Application.find_by!(ecf_id: params[:id])
      end
    end
  end
end
