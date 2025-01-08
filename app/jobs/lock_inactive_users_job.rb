class LockInactiveUsersJob < ApplicationJob
  def perform
    User.lock_inactive_users!
  end
end
