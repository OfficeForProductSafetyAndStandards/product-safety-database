class AddFailureDetailsToTests < ActiveRecord::Migration[6.1]
  def change
    add_column :tests, :failure_details, :text
  end
end
