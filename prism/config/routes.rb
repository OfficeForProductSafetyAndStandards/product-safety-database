Prism::Engine.routes.draw do
  root "triage#index"

  scope "/triage" do
    get "full-risk-assessment-required", to: "triage#full_risk_assessment_required"
    patch "full-risk-assessment-required", to: "triage#full_risk_assessment_required_choose"
    put "full-risk-assessment-required", to: "triage#full_risk_assessment_required_choose"
    get "serious-risk", to: "triage#serious_risk"
    patch "serious-risk", to: "triage#serious_risk_choose"
    put "serious-risk", to: "triage#serious_risk_choose"
    get "serious-risk-rebuttable/:id", to: "triage#serious_risk_rebuttable", as: "serious_risk_rebuttable"
    patch "serious-risk-rebuttable/:id", to: "triage#serious_risk_rebuttable_choose"
    put "serious-risk-rebuttable/:id", to: "triage#serious_risk_rebuttable_choose"
    get "perform-risk-triage", to: "triage#perform_risk_triage"
  end

  get "tasks/:id", to: "tasks#index", as: "tasks"
end
