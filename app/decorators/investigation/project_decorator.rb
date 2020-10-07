class Investigation < ApplicationRecord
  require_dependency "investigation"
  class ProjectDecorator < InvestigationDecorator
  end
end
