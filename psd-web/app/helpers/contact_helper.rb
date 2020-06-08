module ContactHelper
  def name_and_contact_details(name, contact_details)
    if name.present? && contact_details.present?
      "#{name.strip} (#{contact_details.strip})"
    elsif name.present?
      name.strip
    elsif contact_details.present?
      contact_details.strip
    end
  end
end
