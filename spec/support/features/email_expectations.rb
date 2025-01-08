module EmailExpectations
  class HaveEmail
    attr_reader :to, :subject, :with_text

    def initialize(to:, subject:, with_text:)
      @to = to
      @subject = subject
      @with_text = with_text
    end

    def matches?(delivered_emails)
      @delivered_emails = delivered_emails
      return false if delivered_emails.empty?

      @emails_matching_recipient = delivered_emails.select { |delivered_email| delivered_email.recipient == to }

      return false if @emails_matching_recipient.empty?

      @emails_matching_subject = @emails_matching_recipient.select do |delivered_email|
        delivered_email.personalization[:subject_text] == subject
      end

      return false if @emails_matching_subject.empty?

      @emails_matching_text = @emails_matching_subject.select do |delivered_email|
        delivered_email.personalization[:update_text].include?(with_text)
      end

      return false if @emails_matching_text.size != 1

      true
    end

    def failure_message
      if @delivered_emails.empty?
        "No emails were delivered"
      elsif @emails_matching_recipient.empty?
        "No emails delivered to #{to}. Emails were delieved to #{@delivered_emails.collect(&:recipient).join(',')}"
      elsif @emails_matching_subject.empty?
        "Email sent to #{to} but subject was ‘#{@emails_matching_recipient.first.personalization[:subject_text]}’"
      elsif @emails_matching_text.empty?
        "Email sent to #{to} with matching subject but no matching text: \n#{@emails_matching_recipient.first.personalization.inspect}’"
      else
        "More than one email was sent to #{to} with matching subject and text"
      end
    end
  end

  def have_email(to:, subject:, with_text:)
    HaveEmail.new(to:, subject:, with_text:)
  end
end
