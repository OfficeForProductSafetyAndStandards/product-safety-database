require "rails_helper"

RSpec.describe ProductTaxonomyImport do
  # NOTE: Import file validations are tested at the feature level
  subject(:product_taxonomy_import) { build(:product_taxonomy_import) }

  describe "#status" do
    it "returns a human-readable status for the import" do
      expect(product_taxonomy_import.status).to eq("File uploaded")
    end
  end
end
