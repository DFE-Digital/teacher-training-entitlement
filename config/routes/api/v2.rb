namespace :v2, defaults: { format: :json } do
  resources :applications, only: %i[index show]

  match "*path", to: "errors#not_found", via: :all
end
