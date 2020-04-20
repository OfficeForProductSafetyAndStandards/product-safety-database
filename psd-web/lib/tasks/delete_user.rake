namespace :user do
  desc "Marks the given user as deleted, assigning their investigations to their team"
  task delete: :environment do
    user_id = ENV.fetch("ID", nil)
    user_email = ENV.fetch("EMAIL", nil)

    result = DeleteUser.call(user_id: user_id, user_email: user_email)

    if result.success?
      puts "User #{user_id.presence || user_email} successfully marked as deleted."
      puts "User investigations assigned to #{result.team.name}"
    elsif result.error == DeleteUser::MISSING_PARAMS_ERROR
      puts "Error: Need to provide user ID or EMAIL with the call."
      puts "Eg: EMAIL=\"example@example.com\" rake user:delete"
    elsif result.error == DeleteUser::USER_NOT_FOUND_ERROR
      puts "Error: User #{user_id.presence || user_email} not found"
    else
      puts result.error
    end
  end
end
