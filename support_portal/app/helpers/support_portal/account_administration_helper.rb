module SupportPortal
  module AccountAdministrationHelper
    def team_select
      [OpenStruct.new(id: "", name: "")] + ::Team.select(:id, :name).order(name: :asc).map do |team|
        OpenStruct.new(id: team.id, name: team.name)
      end
    end
  end
end
