module ReportPortal
  class BestTeamsController < ApplicationController
    def index
      @by_notifications = Team.not_deleted
                              .joins(:owned_notifications)
                              .where("collaborations.created_at > ?", 1.year.ago)
                              .select("teams.name, count(collaborations.*) as notifications_count")
                              .group("teams.name")
                              .order("notifications_count DESC")

      @by_activity = Team.not_deleted.joins(users: {visits: :events})

    end
  end
end
