namespace :api do
  get :guidance, to: "guidance#index"
  get "guidance/*page", to: "guidance#show", as: :guidance_page
  get "docs/:version", to: "documentation#index", as: :documentation

  namespace :v1, defaults: { format: :json } do
    resources :applications, only: %i[index show], param: :ecf_id do
      member do
        put :reject, path: "reject"
        put :accept, path: "accept"
        put :change_funded_place, path: "change-funded-place"
        put :defer
        put :resume
        put :withdraw
        put :change_schedule, path: "change-schedule"
        post :started, path: "declarations/started", controller: :application_declarations, as: :started_declaration
        post :completed, path: "declarations/completed", controller: :application_declarations, as: :completed_declaration
      end
    end

    resources :outcomes, only: %i[index]

    resources :participants, only: %i[index show], param: :ecf_id

    resources :declarations, only: %i[show index], path: "declarations", param: :ecf_id do
      member do
        put :void, path: "void"
        put :change_delivery_partner, path: "change-delivery-partner"
      end
    end

    resources :schedules, only: %i[index], controller: :course_cohorts

    resources :statements, only: %i[index show], param: :ecf_id

    resources :delivery_partners, path: "delivery-partners", only: %i[index show], param: :ecf_id
  end

  match "*", to: "errors#not_found", via: :all
end
