RSpec.shared_examples "an audit activity for investigation added" do
  let(:investigation) { create(factory, factory_trait) }
  let(:factory_trait) { nil }

  describe ".build_metadata" do
    subject(:metadata) { described_class.build_metadata(investigation) }

    it "adds the investigation data" do
      expect(metadata[:investigation]).to eq({
        title: investigation.decorate.title,
        coronavirus_related: investigation.coronavirus_related?,
        description: investigation.description,
        hazard_type: investigation.hazard_type,
        product_category: investigation.product_category
      })
    end

    context "when there is an owner" do
      it "adds the owner ID" do
        expect(metadata[:owner_id]).to eq(investigation.owner_id)
      end
    end

    context "when there is a complainant" do
      let(:factory_trait) { :with_complainant }

      it "adds the complainant ID" do
        expect(metadata[:complainant_id]).to eq(investigation.complainant.id)
      end
    end
  end

  describe "#owner" do
    subject(:owner) { activity.owner }

    let(:activity) { described_class.create(investigation:, metadata:) }

    # Old records prior to implementation of metadata. In this case this attribute is never used
    context "when there is no metadata" do
      let(:metadata) { nil }

      it "returns nil" do
        expect(owner).to be_nil
      end
    end

    context "when there is no owner ID in the metadata" do
      let(:metadata) { {} }

      it "returns nil" do
        expect(owner).to be_nil
      end
    end

    context "when there is an owner ID in the metadata" do
      let(:user) { create(:user) }
      let(:metadata) { { owner_id: user.id } }

      it "returns the owner" do
        expect(owner).to eq(user)
      end
    end
  end

  describe "#complainant" do
    subject(:complainant) { activity.complainant }

    let(:activity) { described_class.create(investigation:, metadata:) }

    # Old records prior to implementation of metadata. In this case this attribute is never used
    context "when there is no metadata" do
      let(:metadata) { nil }

      it "returns nil" do
        expect(complainant).to be_nil
      end
    end

    context "when there is no complainant ID in the metadata" do
      let(:metadata) { {} }

      it "returns nil" do
        expect(complainant).to be_nil
      end
    end

    context "when there is an complainant ID in the metadata" do
      let(:complainant_factory) { create(:complainant) }
      let(:metadata) { { complainant_id: complainant_factory.id } }

      it "returns the complainant" do
        expect(complainant).to eq(complainant_factory)
      end
    end
  end

  describe "#title" do
    subject(:title) { activity.title(nil) }

    let(:activity) { described_class.create(investigation:, metadata:, title: test_title) }
    let(:test_title) { nil }

    # Old records prior to implementation of metadata. In this case the title is pre-generated and stored in the database
    context "when there is no metadata" do
      let(:metadata) { nil }
      let(:test_title) { "Test title" }

      it "returns the value in the database" do
        expect(title).to eq(test_title)
      end
    end

    context "when there is metadata" do
      let(:metadata) do
        {
          investigation: {
            title: "Test metadata title"
          }
        }
      end

      it "generates the title dynamically" do
        expect(title).to eq("Notification logged: Test metadata title")
      end
    end
  end

  describe "#can_display_all_data?" do
    subject(:can_display) { activity.can_display_all_data?(user) }

    let(:activity) { described_class.create(investigation:, metadata:) }
    let(:user) { create(:user) }

    context "when metadata is present" do
      let(:metadata) { {} }

      # Always return true for new records with metadata, so the view template
      # does not restrict the view of the whole activity. We can now control
      # this more discretely on a per-attribute basis in the view
      it "returns true" do
        expect(can_display).to be true
      end
    end

    # For old records with no metadata the view template has to decide whether
    # to hide the entire activity
    context "when metadata is not present" do
      let(:metadata) { nil }

      context "when there is no complainant" do
        it "returns true" do
          expect(can_display).to be true
        end
      end

      context "when there is a complainant" do
        let(:factory_trait) { :with_complainant }

        context "when the user is on a team collaborating on the case" do
          before do
            create(:collaboration_edit_access, investigation:, collaborator: user.team)
            investigation.reload
          end

          it "returns true" do
            expect(can_display).to be true
          end
        end

        context "when the user is not on a team collaborating on the case" do
          it "returns false" do
            expect(can_display).to be false
          end
        end
      end
    end
  end

  describe "#restricted_title" do
    # This method will only ever be called for older records with no metadata,
    # where the title is pre-generated and stored in the database, so we will
    # set the title here
    subject(:activity) { described_class.create(investigation:, title: "Test title") }

    # titles never contain GDPR data for these activity classes so just return the title
    it "returns the title" do
      expect(activity.restricted_title(nil)).to eq("Test title")
    end
  end
end
