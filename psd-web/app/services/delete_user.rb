class DeleteUser
  include Interactor

  MISSING_PARAMS_ERROR = "Missing parameters: Need either user_id or user_email".freeze
  USER_NOT_FOUND_ERROR = "User not found".freeze

  def call
    context.fail!(error: MISSING_PARAMS_ERROR) if missing_params?

    context.user = if context.user_id
                     User.find(context.user_id)
                   else
                     User.find_by!(email: context.user_email)
                   end
    context.user.mark_as_deleted!

    context.team = context.user.teams.first

    context.user.investigations.each do |investigation|
      investigation.assignee = context.team
      investigation.save
    end
  rescue ActiveRecord::RecordNotFound
    context.fail!(error: USER_NOT_FOUND_ERROR)
  end

private

  def missing_params?
    !context.user_id && !context.user_email
  end
end
