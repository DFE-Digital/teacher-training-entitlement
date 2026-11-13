namespace :webhooks do
  get "docs", to: "documentation#index", as: :documentation
  namespace :trs do
    resources :qualifications, only: %i[show], param: :trn
    resources :messages, only: %i[create]
  end
end
