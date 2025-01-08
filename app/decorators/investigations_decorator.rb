class InvestigationsDecorator < Draper::CollectionDecorator
  delegate :current_page, :total_entries, :total_pages, :per_page, :offset
end
