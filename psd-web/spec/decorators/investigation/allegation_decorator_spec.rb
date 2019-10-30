require "rails_helper"

RSpec.describe Investigation::AllegationDecorator do
  fixtures(:investigations)
  let!(:allegation) { investigations(:one) }

  subject {
    allegation.decorate
  }

  describe '#title' do
    it 'produces the correct title' do
      expect(subject.title).to eq("2 Products – Injuries")
    end
  end
end
