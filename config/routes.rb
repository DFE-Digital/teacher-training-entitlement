Rails.application.routes.draw do
  def dashed_resources(name, **options, &block)
    resources name, **options.merge(path: name.to_s.dasherize), &block
  end

  devise_for :users,
             controllers: { omniauth_callbacks: "omniauth" }

  get "/healthcheck", to: "monitoring#healthcheck", format: :json
  get "/up", to: "monitoring#up"
  get "/robots", to: "robots_txt#show", format: :text, as: "robots_txt"

  resources :institutions, only: [:index]
  resources :private_childcare_providers, only: [:index]

  resources :email_updates do
    collection do
      get "unsubscribe"
      post "unsubscribe"
      get "unsubscribed"
    end
  end

  resource :registration_closed, only: [:show], controller: :registration_closed do
    collection do
      get "change"
    end
  end

  root "registration_wizard#show", step: "start"

  get "/registration/:step", to: "registration_wizard#show", as: "registration_wizard_show"
  get "/registration/:step/change", to: "registration_wizard#show", as: "registration_wizard_show_change", changing_answer: "1"
  patch "/registration/:step", to: "registration_wizard#update", as: "registration_wizard_update"
  patch "/registration/:step/change", to: "registration_wizard#update", as: "registration_wizard_update_change", changing_answer: "1"

  get "/registration-interest/sign-up", to: "interest_notification_sign_up#new"
  post "/registration-interest/sign-up", to: "interest_notification_sign_up#create"
  get "/registration-interest/sign-up/confirm", to: "interest_notification_sign_up#confirm"

  get "/sign-in", to: "session_wizard#show", step: "sign_in"
  get "/session/extend", to: "sessions#extend_session", as: "extend_session"
  match "/sign-out", to: "sessions#destroy", as: "sign_out_user", via: %i[get delete]

  get "/session/:step", to: "session_wizard#show", as: "session_wizard_show"
  patch "/session/:step", to: "session_wizard#update", as: "session_wizard_update"

  get "/cookies", to: "pages#show", page: "cookies"
  get "/accessibility-statement", to: "pages#show", page: "accessibility"
  get "/choose-an-npq-and-provider", to: "pages#show", page: "choose_an_npq_and_provider"
  get "/closed_registration_exception", to: "pages#show", page: "closed_registration_exception"

  resource :cookie_preferences do
    member do
      post "hide"
    end
  end

  resources :applications, only: %i[index show], param: :ecf_id, module: :applications do
    namespace :change_provider, path: "change-provider" do
      dashed_resources :contact_us, only: %i[index]
      dashed_resources :start, only: %i[index create]
      dashed_resources :providers, only: %i[index create]
      dashed_resources :check_answers, only: %i[index create]
    end
  end

  draw("/api/v1")

  draw("/admin")

  get "maintenance_banners/dismiss", to: "maintenance_banners#dismiss", as: :maintenance_banner_dismiss

  get "/404", to: "errors#not_found", via: :all
  get "/422", to: "errors#unprocessable_content", via: :all
  get "/500", to: "errors#internal_server_error", via: :all

  get "/development_login", to: "registration_wizard#development_login"

  get "/registrations/:journey_slug", to: "registrations#show"
  get "/registrations/:journey_slug/:step_slug", to: "registrations#show", as: :registration
  patch "/registrations/:journey_slug/:step_slug", to: "registrations#update"
  put "/registrations/:journey_slug/:step_slug", to: "registrations#update"
end
