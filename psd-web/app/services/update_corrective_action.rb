class UpdateCorrectiveAction
  include Interactor
  delegate :user, :corrective_action, :corrective_action_params, to: :context

  def call
    corrective_action.set_dates_from_params(corrective_action_params)
    corrective_action.update!(corrective_action_params)
  end
end
