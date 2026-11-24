class LoggedInController < ApplicationController
private

  def authenticate_teacher!
    redirect_to root_path unless current_teacher
  end
end
