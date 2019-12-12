require "rails_helper"

RSpec.describe ElasticsearchQuery, :with_elasticsearch, :with_keycloak_config do
  let(:assignee)   { create :user }
  let(:allegation) { create :allegation, assignable: assignee }
  let(:project)    { create :project, assignable: assignee }
  let(:filters)    { {} }
  let(:sorting)    { {} }

  before { Investigation.import }

  subject { described_class.new(query, filters, sorting) }

  def do_search(query)
    Investigation.full_search(query).records.to_a
  end

  describe "Fuzziness" do
    let(:query) { "abcdefgh" }
    before do
      allegation.update!(description: "abcdefgh")
      project.update!(description: "abcdef")
    end

    it "should not be too fuzzy" do
      expect(do_search(subject)).to include(allegation)
      expect(do_search(subject)).to_not include(project)
    end
  end
end
