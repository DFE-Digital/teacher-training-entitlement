namespace :api do
  get :guidance, to: "guidance#index"
  get "guidance/*page", to: "guidance#show", as: :guidance_page
  get "docs/:version", to: "documentation#index", as: :documentation

  namespace :v1, defaults: { format: :json } do
    resources :applications, only: %i[index show], param: :ecf_id do
      member do
        post :reject, path: "reject"
        post :accept, path: "accept"
        put :change_funded_place, path: "change-funded-place"
      end
    end

    resources :participant_outcomes, only: %i[index], path: "participants/outcomes", as: :participant_outcomes

    resources :participants, only: %i[index show], param: :ecf_id do
      member do
        put :change_schedule, path: "change-schedule"
        put :defer
        put :resume
        put :withdraw

        scope module: :participants do
          resources :outcomes, only: %i[create index], as: :participants_outcomes
        end
      end
    end

    resources :declarations, only: %i[create show index], path: "participant-declarations", param: :ecf_id do
      member do
        put :void, path: "void"
        put :change_delivery_partner, path: "change-delivery-partner"
      end
    end

    resources :statements, only: %i[index show], param: :ecf_id

    resources :delivery_partners, path: "delivery-partners", only: %i[index show], param: :ecf_id
  end

  namespace :teacher_record_service, path: "teacher-record-service", defaults: { format: :json } do
    namespace :v1 do
      resources :qualifications, only: %i[show], param: :trn
    end
  end
end
