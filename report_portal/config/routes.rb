ReportPortal::Engine.routes.draw do
  resources :summary, only: %i[index]

  root "dashboard#index", as: :report_root
end
