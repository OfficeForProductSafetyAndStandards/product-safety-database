module TableAccessibilityHelper
  # Generates a descriptive text for screen readers about a notification
  # @param notification [Investigation] The notification to describe
  # @param page_name [String] The current page name
  # @return [String] Screen reader friendly description
  def notification_screen_reader_description(notification, page_name = nil)
    description_parts = []
    description_parts << "Notification number: #{notification.pretty_id}"

    description_parts << (
      if non_search_cases_page_names.include?(page_name)
        "Created: #{notification.created_at.to_formatted_s(:govuk)}"
      else
        "Owner: #{investigation_owner(notification)}"
      end
    )

    description_parts << (
      if page_name == "assigned_cases"
        "Assigner: #{sanitize(notification.owner_team&.name)}"
      else
        "Hazard type: #{sanitize(notification.hazard_type.presence || 'Not provided')}"
      end
    )

    description_parts << "Product count: #{pluralize notification.products.count, 'product'}"
    description_parts.join(". ")
  end

  # Calculates the row index for screen readers in notification tables
  # Each notification has 3 rows (title, meta, status)
  # For investigation 0, rows are 1,2,3
  # For investigation 1, rows are 4,5,6 etc.
  # @param investigation_counter [Integer] The index of the current investigation
  # @param row_number [Integer] The row number within the current investigation (1-3)
  # @return [Integer] The calculated row index
  def calculate_row_index(investigation_counter, row_number)
    (investigation_counter * 3) + row_number
  end

  # Generates a unique ID for screen reader descriptions
  # @param prefix [String] Prefix for the ID
  # @param record [ActiveRecord::Base] The record to generate ID for
  # @return [String] A unique ID for aria-describedby
  def screen_reader_description_id(prefix, record)
    "description-#{prefix}-#{record.id}"
  end

  # Generates table header attributes for accessibility
  # @param text [String] The header text
  # @return [Hash] HTML attributes for the header
  def accessible_table_header_attributes(text)
    {
      scope: "col",
      "aria-label": text
    }
  end
end
