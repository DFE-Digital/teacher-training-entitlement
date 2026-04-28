require "rails_helper"

RSpec.describe SessionTimeout, type: :controller do
  controller(ApplicationController) do
    skip_before_action :authenticate_user!

    def index
      head :ok
    end
  end

  let!(:user) { create(:user) }

  before do
    session[:user_id] = user.id
  end

  it "allows access when session is active" do
    session[:last_activity_at] = 15.minutes.ago
    get :index
    expect(response).to have_http_status(:ok)
  end

  it "expires session after 30 minutes of inactivity" do
    session[:last_activity_at] = 31.minutes.ago
    get :index
    expect(response).to redirect_to(root_path)
    expect(flash[:notice]).to eq("Your session has expired due to inactivity.")
    expect(session[:user_id]).to be_nil
  end
end
