class RemoveUniquenessConstraintForInvestigationBusinesses < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    remove_index :investigation_businesses, column: %i[investigation_id business_id]
    add_index :investigation_businesses, %i[investigation_id business_id], algorithm: :concurrently
  end

  def down
    remove_index :investigation_businesses, column: %i[investigation_id business_id]
    results = execute <<-SQL
    SELECT dups.id_groups
      FROM
        (SELECT  array_agg(ib.id) AS id_groups
        FROM investigation_businesses ib
        WHERE EXISTS
          (
          SELECT 1
          FROM investigation_businesses tmp
          WHERE tmp.business_id = ib.business_id
          LIMIT 1
          OFFSET 1
         )
        GROUP BY ib.investigation_id
    ) AS dups
    SQL

    results.each do |id_array|
      InvestigationBusiness.where(id: id_array[1..]).delete_all
    end

    add_index :investigation_businesses, %i[investigation_id business_id], unique: true
  end
end
