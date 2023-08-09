class InvestigationProductDecorator < Draper::Decorator
  decorates_association :product
  delegate_all

  def owning_team_link
    return "No owner" if product.owning_team.nil?
    return "Your team is the product record owner" if product.owning_team == h.current_user.team

    h.link_to product.owning_team.name, h.owner_investigation_investigation_product_path(investigation, object), class: "govuk-link govuk-link--no-visited-state"
  end

  def product_overview_summary_list
    h.govukSummaryList(
      classes: "govuk-summary-list govuk-summary-list--no-border govuk-!-margin-bottom-4 opss-summary-list-mixed opss-summary-list-mixed--compact",
      rows: [
        {
          key: { text: "Last updated" },
          value: { text: h.date_or_recent_time_ago(product.updated_at) }
        },
        {
          key: { text: "Created" },
          value: { text: h.date_or_recent_time_ago(product.created_at) }
        },
        {
          key: { text: "Product record owner" },
          value: { html: owning_team_link }
        }
      ]
    )
  end

  def ucr_numbers_list
    ucr_numbers.pluck(:number)
  end
end
