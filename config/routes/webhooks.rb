namespace :webhooks do
  namespace :trs do
    resources :qualifications, only: %i[show], param: :trn
  end
end
