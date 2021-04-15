module ActiveModel
  module Types
    class TeamsWithAccessSearchParams < ActiveRecord::Type::Value
      def cast(team_with_access_search_params)
        return team_with_access_search_params if team_with_access_search_params.is_a?(TeamsWithAccessSearchFormFields)

        TeamsWithAccessSearchFormFields.new(team_with_access_search_params)
      end
    end
  end
end
