module FormattedDescription
  extend ActiveSupport::Concern

  def description
    h.simple_format(object.description) if object.description.present?
  end
end
