class SyncKeycloakTeamsAndUsersJob < ApplicationJob
  def perform
    KeycloakService.sync_orgs_and_users_and_teams

    # Set mobile phone number as verified for all users who have added a mobile number.
    User.where.not(mobile_number: nil).update_all(mobile_number_verified: true)
  end
end
