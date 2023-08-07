class AddAuthorisedRepresentativeChoiceToInvestigationBusinesses < ActiveRecord::Migration[7.0]
  def change
    add_column :investigation_businesses, :authorised_representative_choice, :string
  end
end
