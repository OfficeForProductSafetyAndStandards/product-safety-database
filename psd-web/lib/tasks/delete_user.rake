namespace :user do
  desc "Marks the given user as Deleted"
  task delete: :environment do
    if (id = ENV.fetch("ID", nil))
      User.find(id).mark_as_deleted!
      puts "User with id: #{id} successfully marked as deleted"
    elsif (email = ENV.fetch("EMAIL", nil))
      User.find_by!(email: email).mark_as_deleted!
      puts "User with email: #{email} successfully marked as deleted"
    else
      puts "Error: Need to provide user ID or EMAIL with the call."
      puts "Eg: EMAIL=\"example@example.com\" rake user:delete"
    end
  end
end
