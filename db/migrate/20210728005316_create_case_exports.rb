class CreateCaseExports < ActiveRecord::Migration[6.1]
  def change
    # rubocop:disable Style/SymbolProc
    create_table :case_exports do |t|
      t.timestamps
    end
    # rubocop:enable Style/SymbolProc
  end
end
