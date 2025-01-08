module OpssAsideHelper
  def opss_aside(title:, text:, classes: nil)
    tag.aside(safe_join([
      tag.h3(title, class: "govuk-heading-s govuk-!-margin-bottom-1 opss-secondary-text"),
      tag.p(text, class: "govuk-body-s govuk-!-margin-0 opss-secondary-text")
    ]), class: class_names("govuk-!-padding-3 opss-border-all opss-rounded-corners opss-drop-shadow", classes))
  end
end
