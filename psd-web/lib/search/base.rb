module Search
  class Base
    attr_reader :f

    def initialize(search_form)
      @f = search_form
    end

    def search
      @search = Investigation
      # search for type
      filter_by_type
      # search for status
      filter_by_status
      # search for creator
      filter_by_creator
      # search for assignee
      filter_by_assignee
      puts @search.to_sql
      @search
      # order
    end

  private

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
                     Investigation.joins(:source).where("sources.user_id = ?", f.created_by_me)
                   else
                     Investigation.none#joins(:source)
                   end
      relations << if f.created_by_team_0 != "unchecked"
                     Investigation.joins(:source).where("sources.user_id IN (?)", Team.find(f.created_by_team_0).users.pluck(:id))
                   else
                     Investigation.none#joins(:source)
                   end
      if f.created_by_someone_else?
        ids = [f.created_by_someone_else_id]
        team = Team.find_by(id: f.created_by_someone_else_id)
        if team
          ids << team.users.pluck(:id)
        end
        relations << Investigation.joins(:source).where("sources.user_id IN (?)", ids.flatten.uniq.compact)
      else
        relations << Investigation.none#.joins(:source)
      end
      or_relation = Investigation.none#joins(:source)
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
      return

      if f.assigned_to_me != "unchecked"
        @search = @search.joins(:source).where("sources.user_id = ?", f.assigned_to_me)
      end
      if f.created_by_team_0 != "unchecked"
        @search = @search.joins(:source).where("sources.user_id IN (?)", Team.find(f.created_by_team_0).users.pluck(:id))
      end
      if f.created_by_someone_else?
        ids = [f.created_by_someone_else_id]
        team = Team.find_by(id: f.created_by_someone_else_id)
        if team
          ids << team.users.pluck(:id)
        end
        @search = @search.joins(:source).where("sources.user_id IN (?)", ids.flatten.uniq.compact)
      end
    end
  end
end
