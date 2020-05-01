namespace :user do
  desc "Marks the given user as deleted, assigning their investigations to their team"
  task delete: :environment do
    # The issue raised by rubocop does not apply when the method is declared inside
    # the task block.
    # rubocop:disable Rake/MethodDefinitionInTask
    def delete_user(id, email)
      user = id ? User.find(id) : User.find_by!(email: email)

      result = DeleteUser.call(user: user)
      if result.success?
        puts "User #{id.presence || email} successfully marked as deleted."
        puts "User investigations assigned to #{result.team.name}"
      else
        raise RuntimeError, result.error
      end
    rescue ActiveRecord::RecordNotFound
      raise RuntimeError, "Error: User #{id.presence || email} not found"
    end
    # rubocop:enable Rake/MethodDefinitionInTask

    user_id = ENV.fetch("ID", nil)
    user_email = ENV.fetch("EMAIL", nil)

    if !user_id && !user_email
      raise RuntimeError, "Error: Need to provide user ID or EMAIL with the call.\nEg: EMAIL=example@example.com rake user:delete"
    else
      delete_user(user_id, user_email)
    end
  end
end
