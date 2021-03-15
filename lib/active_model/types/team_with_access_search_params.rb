module ActiveModel
  module Types
    class TeamWithAccessSearchParams

      def cast(team_with_access_search_params)
        TeamWithAccessSearchFormFields.new(team_with_access_search_params)
      end

    end
  end
end
