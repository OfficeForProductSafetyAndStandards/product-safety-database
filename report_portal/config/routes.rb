ReportPortal::Engine.routes.draw do

  resources :teams, only: %i[index]
  resources :summary, only: %i[index]

  root "dashboard#index", as: :report_root
end
