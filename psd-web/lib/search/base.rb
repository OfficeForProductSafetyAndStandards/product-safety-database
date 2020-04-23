module Search
  class Base
    attr_reader :f

    def initialize(search_form:, user_id:, team_id:)
      @f = search_form
      @user_id = user_id
      @team_id = team_id
    end

    def search
      @search = Investigation.unscoped
      search_by_keyword
      filter_by_type
      filter_by_status
      filter_by_creator
      filter_by_assignee
      sort
      @search
    end

  private

    def search_by_keyword
      if f.q.present?
        @search = @search.where("search_index @@ to_tsquery('english',  ?)", f.q.split(" ").join(" & "))
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
        if f.created_by_someone_else_id != "unchecked"
          ids = [f.created_by_someone_else_id]
          team = Team.find_by(id: f.created_by_someone_else_id)
          if team
            ids << team.users.pluck(:id)
          end
          relations << Investigation.joins(:source).where("sources.user_id IN (?)", ids.flatten.uniq.compact)
        else
          # use ids different then current user and team
          team_users_ids = Team.find(@team_id).users.pluck(:id)
          team_users_ids << @user_id
          relations << Investigation.joins(:source).where("sources.user_id NOT IN (?)", team_users_ids.uniq)
        end
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
      if f.assigned_to_someone_else != "unchecked"
        if f.assigned_to_someone_else_id != "unchecked" && f.assigned_to_someone_else_id.present?
          ids = [f.assigned_to_someone_else_id]
          team = Team.find_by(id: f.assigned_to_someone_else_id)
          if team
            ids << team.users.pluck(:id)
          end
          team = Investigation.where("assignable_type = 'Team'").where(assignable_id: f.assigned_to_someone_else_id)
          team = team.or(Investigation.where("assignable_type = 'User'").where(assignable_id: ids.flatten.compact.uniq)) if ids.present?
          relations << team.or(Investigation.where("assignable_type = 'User'").where(assignable_id: f.assigned_to_someone_else_id))
        else # not in user_id or team_id
          ids = [@user_id]
          team = Team.find_by(id: @team_id)
          if team
            ids << team.users.pluck(:id)
          end
          team = Investigation.where("(assignable_type = 'Team' AND assignable_id != ?)", @team_id)
          team = team.or(Investigation.where("(assignable_type = 'User' AND assignable_id NOT IN (?))", ids.flatten.compact.uniq))
          relations << team
        end
      else
        relations << Investigation.none
      end
      or_relation = Investigation.none
      or_relation = or_relation.or(relations[0]) if relations[0].present?
      or_relation = or_relation.or(relations[1]) if relations[1].present?
      or_relation = or_relation.or(relations[2]) if relations[2].present?
      @search = @search.merge(or_relation) if or_relation.present?
    end

    def sort
      case f.sort_by
      when "recent"
        @search = @search.order("updated_at DESC")
      when "oldest"
        @search = @search.order("updated_at ASC")
      when "newest"
        @search = @search.order("created_at DESC")
      end
    end
  end
end
