require 'rails_helper'

RSpec.describe ComplainantDecorator do
  fixtures :complainants

  let(:complainant) { complainants(:one) }

  subject { complainant.decorate }

  describe '#summary_list' do
    let(:summary_list) { Capybara.string(subject.summary_list) }

    let(:expected_contact_details) do
      "#{complainant.name}#{complainant.phone_number}#{complainant.email_address}#{complainant.other_details}"
    end

    it 'displays the complainant summary list' do
      expect(summary_list).to have_css('dl dt.govuk-summary-list__key',   text: 'Type')
      expect(summary_list).to have_css('dl dd.govuk-summary-list__value', text: complainant.complainant_type)
      expect(summary_list).to have_css('dl dt.govuk-summary-list__key',   text: 'Contact details')
      expect(summary_list).to have_css('dl dd.govuk-summary-list__value', text: expected_contact_details)
    end

    context 'when no contact details are provided' do
      let(:complainant) { complainants(:two) }

      it 'displays the complainant summary list' do
        expect(summary_list).to have_css('dl dt.govuk-summary-list__key',   text: 'Type')
        expect(summary_list).to have_css('dl dd.govuk-summary-list__value', text: complainant.complainant_type)
        expect(summary_list).not_to have_css('dl dt.govuk-summary-list__key',   text: 'Contact details')
      end
    end
  end
end
