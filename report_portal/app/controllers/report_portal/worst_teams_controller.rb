module ReportPortal
  class WorstTeamsController < ApplicationController
    def index
      @all_teams = Team.not_deleted.order(:name)

      # Teams with no investigations
      @by_notifications = @all_teams.left_outer_joins(:owned_notifications).where(collaborations: { id: nil })

      # Teams with no products
      @by_products = @all_teams.left_outer_joins(:owned_products).where(products: { id: nil })

      # Teams with no active users
      @by_users = @all_teams.left_outer_joins(:users).where('users.last_sign_in_at < ?', 3.months.ago).select('teams.*, count(users.*) as users_count').group('teams.id')
    end
  end
end
