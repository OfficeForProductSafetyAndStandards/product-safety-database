module Search
  class Base
    attr_reader :f

    def initialize(search_form:, user_id:, team_id:)
      @f = search_form
      @user_id = user_id
      @team_id = team_id
    end

    def search
      @search = Investigation
      search_by_keyword
      filter_by_type
      filter_by_status
      filter_by_creator
      filter_by_assignee
      # puts @search.to_sql
      # TODO: add order
      @search
    end

  private

    def search_by_keyword
      if f.q.present?
        @search = @search.where("search_index @@ to_tsquery(?)", f.q)
      end
    end

    def filter_by_status
      ignore_status = !f.status_open? && !f.status_closed?
      return @search if ignore_status

      if f.status_open? && f.status_closed?
        @search = @search.where("is_closed IN (?)", [true, false])
        return
      end
      if f.status_open?
        @search = @search.where(is_closed: false)
      end
      if f.status_closed?
        @search = @search.where(is_closed: true)
      end
    end

    def filter_by_creator
      relations = []
      relations << if f.created_by_me != "unchecked"
                     Investigation.joins(:source).where("sources.user_id = ?", @user_id)
                   else
                     Investigation.none
                   end
      relations << if f.created_by_team_0 != "unchecked"
                     Investigation.joins(:source).where("sources.user_id IN (?)", Team.find(@team_id).users.pluck(:id))
                   else
                     Investigation.none
                   end
      if f.created_by_someone_else?
        ids = [f.created_by_someone_else_id]
        team = Team.find_by(id: f.created_by_someone_else_id)
        if team
          ids << team.users.pluck(:id)
        end
        relations << Investigation.joins(:source).where("sources.user_id IN (?)", ids.flatten.uniq.compact)
      else
        relations << Investigation.none
      end
      or_relation = Investigation.none
      or_relation = or_relation.or(relations[0]) if relations[0].present?
      or_relation = or_relation.or(relations[1]) if relations[1].present?
      or_relation = or_relation.or(relations[2]) if relations[2].present?
      @search = @search.merge(or_relation) if or_relation.present?
    end

    def filter_by_type
      types = []
      if f.allegation?
        types << "Investigation::Allegation"
      end
      if f.project?
        types << "Investigation::Project"
      end
      if f.enquiry?
        types << "Investigation::Enquiry"
      end
      if types.present?
        @search = @search.where(type: types)
      end
    end

    def filter_by_assignee
      relations = []
      relations << if f.assigned_to_me != "unchecked"
        Investigation.where("assignable_type = 'User'").where(assignable_id: @user_id)
      else
        Investigation.none
      end
      relations << if f.assigned_to_team_0 != "unchecked"
        team = Investigation.where("assignable_type = 'Team'").where(assignable_id: @team_id)
        team_users = Team.find(@team_id).users.pluck(:id)
        team.or(Investigation.where("assignable_type = 'User'").where(assignable_id: team_users))
      else
        Investigation.none
      end
      relations << if f.assigned_to_someone_else != "unchecked"
        ids = [f.assigned_to_someone_else_id]
        team = Team.find_by(id: f.assigned_to_someone_else_id)
        if team
          ids << team.users.pluck(:id)
        end
        team = Investigation.where("assignable_type = 'Team'").where(assignable_id: f.assigned_to_someone_else_id)
        team = team.or(Investigation.where("assignable_type = 'User'").where(assignable_id: ids.flatten.compact.uniq)) if ids.present?
        team.or(Investigation.where("assignable_type = 'User'").where(assignable_id: f.assigned_to_someone_else_id))
      else
        Investigation.none
      end
      or_relation = Investigation.none
      or_relation = or_relation.or(relations[0]) if relations[0].present?
      or_relation = or_relation.or(relations[1]) if relations[1].present?
      or_relation = or_relation.or(relations[2]) if relations[2].present?
      @search = @search.merge(or_relation) if or_relation.present?
    end
  end
end
