# Based on https://github.com/alphagov/govuk-frontend/blob/master/src/govuk/components/fieldset/template.njk
module GovukFieldsetHelper

  def govukFieldset(classes: "", describedBy: "", legend: {}, attributes: {}, &block)
    tag.fieldset class: "govuk-fieldset" do
      legend = capture do
        tag.legend class: "govuk-fieldset__legend #{legend[:classes]}" do
          if legend[:isPageHeading]
            tag.h1 class: "govuk-fieldset__heading" do
              legend[:html].presence || legend[:text]
            end
          else
            legend[:html].presence || legend[:text]
          end
        end
      end
      content = capture(&block)

      legend + content
    end
  end
end
