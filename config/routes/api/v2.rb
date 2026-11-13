namespace :v2, defaults: { format: :json } do
  resources :training, only: %i[index], controller: :training

  match "*path", to: "errors#not_found", via: :all
end
