module ContactHelper
  def name_and_email(name, email)
    if name.present? && email.present?
      "#{name.strip} (#{email.strip})"
    elsif name.present?
      name.strip
    elsif email.present?
      email.strip
    end
  end
end
