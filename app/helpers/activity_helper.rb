module ActivityHelper
  def updated_field(field)
    if field.present?
      tag.strong(field)
    else
      "Removed"
    end
  end
end
