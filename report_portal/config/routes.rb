ReportPortal::Engine.routes.draw do

  resources :best_teams, path: 'best-teams', only: %i[index]
  resources :worst_teams, path: 'worst-teams', only: %i[index]
  resources :summary, only: %i[index]

  root "dashboard#index", as: :report_root
end
