Prism::Engine.routes.draw do
  root "triage#index"

  scope "/triage" do
    get "serious-risk", to: "triage#serious_risk"
    patch "serious-risk", to: "triage#serious_risk_choose"
    put "serious-risk", to: "triage#serious_risk_choose"
    get "serious-risk-rebuttable/:id", to: "triage#serious_risk_rebuttable", as: "serious_risk_rebuttable"
    patch "serious-risk-rebuttable/:id", to: "triage#serious_risk_rebuttable_choose"
    put "serious-risk-rebuttable/:id", to: "triage#serious_risk_rebuttable_choose"
    get "full-risk-assessment-required/:id", to: "triage#full_risk_assessment_required", as: "full_risk_assessment_required"
    patch "full-risk-assessment-required/:id", to: "triage#full_risk_assessment_required_choose"
    put "full-risk-assessment-required/:id", to: "triage#full_risk_assessment_required_choose"
    get "perform-risk-triage(/:id)", to: "triage#perform_risk_triage", as: "perform_risk_triage"
  end

  resources :risk_assessment, path: "risk-assessment", only: [] do
    resources :tasks, only: %i[index] do
      collection do
        scope module: :tasks do
          resources :define, only: %i[show update]
          resources :identify, only: %i[show update]
          resources :create, only: [] do
            # Allow a `harm_scenario_id` after the wizard step name for all harm scenario steps
            member do
              get ":harm_scenario_id", to: "create#show", as: ""
              patch ":harm_scenario_id", to: "create#update"
              put ":harm_scenario_id", to: "create#update"
            end
          end
          resources :evaluate, only: %i[show update]
        end
        scope "/harm-scenarios" do
          get "create", to: "tasks#create_harm_scenario", as: "create_harm_scenario"
          get "remove/:harm_scenario_id", to: "tasks#remove_harm_scenario", as: "remove_harm_scenario"
          delete "delete/:harm_scenario_id", to: "tasks#delete_harm_scenario", as: "delete_harm_scenario"
        end
      end
    end
  end

  scope "/api" do
    get "overall-probability-of-harm-and-risk-level", to: "api#overall_probability_of_harm_and_risk_level"
  end
end
