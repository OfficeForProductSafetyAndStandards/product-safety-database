module Investigations::SupportingInformationHelper
  def creator_caption(creator, viewing_user)
    created_by = creator&.display_name(viewer: viewing_user) || "anonymous"
    tag.span("by #{created_by}", class: "govuk-caption-m")
  end
end
