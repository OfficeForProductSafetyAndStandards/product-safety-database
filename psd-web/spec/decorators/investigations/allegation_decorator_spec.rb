require "rails_helper"

RSpec.describe Investigations::AllegationDecorator do
  let(:allegation) { investigations(:one) }

  subject { allegation.decorate }

  describe '#title' do
    it 'produces the correct title' do
      expect(subject.title).to eq('asda')
    end
  end
end
