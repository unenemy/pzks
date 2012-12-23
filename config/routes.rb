Pzks::Application.routes.draw do
  match "/com", to: "home#com", as: :com
  match "/scopes", to: "home#scopes", as: :scopes
  root to: "home#index"
end
