module Search
  class Index
    INDEX_QUERY =<<-SQL
    UPDATE investigations ii SET search_index =
     to_tsvector('english', coalesce(i.description,'') || ' ' || coalesce(i.product_category,'') || ' ' || coalesce(p.name,'') || ' ' || coalesce(p.description,''))
     FROM investigations AS i
     LEFT JOIN investigation_products AS ip ON ip.investigation_id = i.id
     LEFT JOIN products AS p ON ip.product_id = p.id
     WHERE ii.id = i.id
SQL
    INDEX_QUERY2 =<<-SQL
    UPDATE investigations SET search_index =
     to_tsvector('english', coalesce(i.description,'') || ' ' || coalesce(i.product_category,''))
     FROM investigations AS i
SQL
    DEBUG =<<-SQL
    SELECT
     to_tsvector('english', coalesce(i.description,'') || ' ' || coalesce(i.product_category,'') || ' ' || coalesce(p.name,'') || ' ' || coalesce(p.description,''))
     FROM investigations AS i
     LEFT JOIN investigation_products AS ip ON ip.investigation_id = i.id
     LEFT JOIN products AS p ON ip.product_id = p.id
SQL

    def self.update_index
      puts DEBUG
      ActiveRecord::Base.connection.exec_query INDEX_QUERY
    end
  end
end
