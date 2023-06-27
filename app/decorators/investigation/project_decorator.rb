class Investigation < ApplicationRecord
  require_dependency "investigation"
  class ProjectDecorator < InvestigationDecorator
    def title
      user_title || pretty_id
    end
  end
end
