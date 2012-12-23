Pzks::Application.routes.draw do
  match "/com", to: "home#com", as: :com
  match "/scopes", to: "home#scopes", as: :scopes
  match "/pipeline", to: "home#pipeline", as: :pipeline
  root to: "home#index"
end
