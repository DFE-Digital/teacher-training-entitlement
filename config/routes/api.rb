namespace :api do
  get :guidance, to: "guidance#index"
  get "guidance/*page", to: "guidance#show", as: :guidance_page
  get "docs/:version", to: "documentation#index", as: :documentation

  draw("/api/v1")
  draw("/api/v2")

  match "*", to: "errors#not_found", via: :all
end
