namespace :admin do
  get "/", to: "dashboards#index"

  concern :cohortable do |options|
    member do
      get "cohorts/:cohort_id", to: options[:to], as: :cohort
    end

    collection do
      get "cohorts/:cohort_id", to: options[:to], as: :cohort
    end
  end

  resources :webhook_messages, only: %i[index show], path: "webhook-messages" do
    resources :processing_jobs, only: %i[create], controller: "webhook_messages/processing_jobs", path: "processing-jobs"
  end

  resources :features, only: %i[index show update]
  resources :admins, only: %i[index new create destroy]
  resources :super_admins, only: %i[update]
  resources :dashboards, only: %i[index show], controller: "dashboards", path: "dashboards", param: "name"
  resources :registration_closed, only: %i[index], path: "registration-closed"
  resources :glossary, only: %i[index]
  resources :api_test_scenarios, only: %i[index create], path: "api-test-scenarios"

  namespace :registration_closed, path: "registration-closed" do
    resources :reopening_email_subscriptions, path: "reopening-email-subscriptions" do
      member do
        get "unsubscribe"
        post "unsubscribe"
      end
      collection do
        get "all_users"
        get "senco"
      end
    end
    resources :closed_registration_users, path: "closed-registration-users" do
      member do
        get "destroy"
        delete "destroy"
      end
    end
  end

  resources :applications, only: %i[index show] do
    concerns :cohortable, to: "applications#index"
    collection do
      resources :reviews, controller: "applications/reviews", as: "application_reviews", only: %i[index show] do
        resource :review_status, controller: "applications/review_statuses", only: %i[edit update]
        member do
          namespace :applications, path: nil do
            namespace :reviews, path: nil do
              resource :history, controller: "/admin/applications/history", only: %i[show]
            end
          end
        end
      end
    end
    member do
      resources :declarations, controller: "applications/declarations", as: "application_declarations", only: %i[index]
      namespace :applications, path: nil do
        resource :revert_to_pending, controller: "revert_to_pending", only: %i[new create]
        resource :change_status, only: %i[new create]
        resource :change_funding_eligibility, only: %i[new create]
        resource :change_lead_provider, controller: "change_lead_provider", only: %i[show create]
        resource :notes, only: %i[edit update]
        resource :change_cohort, controller: "change_cohort", only: %i[show create]
        resource :history, controller: "history", only: %i[show]
        resource :outcome, controller: "outcome", only: %i[show]
      end
    end
  end

  resources :cohorts do
    resources :schedules, except: :index do
      resources :milestones, except: :show
    end
    resources :statements, only: %i[new create show]
    member { get :download_contracts, path: "download-contracts" }
  end

  resources :delivery_partners, path: "delivery-partners", except: %i[show destroy] do
    resource :delivery_partnerships, path: "delivery-partnerships", only: :edit
    collection do
      post :continue
    end
    member do
      post :continue
    end
  end

  resources :schools, only: %i[index show] do
    collection do
      resource :eligibility_lists, controller: "eligibility_lists", only: %i[show create], path: "eligibility-lists"
    end
  end

  resources :courses, only: %i[index show]
  resources :users, only: %i[index show] do
    member do
      namespace :users, path: nil do
        resource :change_trn, controller: "change_trn", only: %i[show create]
      end
    end
  end

  namespace :finance do
    resources :contracts, only: [] do
      member do
        resource :change_per_participant, controller: "contracts/change_per_participant", only: %i[show create] do
          post :confirmed, on: :member
        end
      end
    end

    resources :statements, only: %i[index show] do
      resources :adjustments, controller: "statements/adjustments" do
        collection do
          post :add_another
        end

        member do
          get :delete
        end
      end

      member do
        resource :assurance_report, controller: "statements/assurance_reports", only: "show"
        resource :payment_authorisation, controller: "statements/payment_authorisations", only: %i[new create]
        resources :voided, controller: "statements/voided", only: :index
        get :print_provider
        get :print_dfe_user

        namespace :statements, path: nil do
          resource :change_deadline_date, controller: "change_deadline_date", only: %i[show create]
          resource :change_payment_date, controller: "change_payment_date", only: %i[show create]
        end
      end
    end
  end

  resources :lead_providers, only: %i[index show], path: "providers" do
    concerns :cohortable, to: "lead_providers#show"
  end
  resources :admins, only: %i[index]

  resources :bulk_operations, only: %i[index], path: "bulk-changes"

  namespace :bulk_operations, path: "bulk-changes" do
    resources :revert_applications_to_pending, controller: "revert_applications_to_pending", only: %i[index create show] do
      post "run", on: :member
    end

    resources :reject_applications, controller: "reject_applications", only: %i[index create show] do
      post "run", on: :member
    end

    resources :submit_declarations, controller: "submit_declarations", only: %i[index create show] do
      post "run", on: :member
    end

    resources :update_and_verify_trns, controller: "update_and_verify_trns", only: %i[index create show] do
      post "run", on: :member
    end

    resources :backfill_declaration_delivery_partners, controller: "backfill_declaration_delivery_partners", only: %i[index create show] do
      post "run", on: :member
    end
  end

  resources :actions_log, path: "actions-log", controller: "actions_log", only: %i[index show] do
    collection do
      post :search
    end
  end
end
