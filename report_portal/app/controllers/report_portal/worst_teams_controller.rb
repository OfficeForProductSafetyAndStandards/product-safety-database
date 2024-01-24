module ReportPortal
  class WorstTeamsController < ApplicationController
    def index
      @by_notifications = Team.not_deleted.joins(:owned_notifications).select("teams.name, count(collaborations.*) as notifications_count").group("teams.name").order("notifications_count DESC")
    end
  end
end
