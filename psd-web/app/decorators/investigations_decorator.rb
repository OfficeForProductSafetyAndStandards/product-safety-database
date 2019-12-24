class InvestigationsDecorator < Draper::CollectionDecorator
  def total_pages
    object.total_pages
  end
end
