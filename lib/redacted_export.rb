module RedactedExport
  extend ActiveSupport::Concern

  class_methods do
    def redacted_export_attributes
      @redacted_export_attributes ||= []
    end

  protected

    def redacted_export_with(*attributes)
      RedactedExport.register_model_attributes self, *attributes
    end
  end

  def self.registry
    @registry ||= Registry.new
  end

  def self.register_model_attributes(model, *attributes)
    registry.register_model_attributes(model, *attributes)
  end

  def self.register_table_attributes(table, *attributes)
    registry.register_table_attributes(table, *attributes)
  end

  class Registry < Hash
    def register_model_attributes(model, *attributes)
      register_table_attributes(model.table_name, *attributes)
    end

    def register_table_attributes(table, *attributes)
      self[table] ||= []
      self[table].concat attributes
      self[table].uniq!
    end

    def with_all_tables
      ActiveRecord::Base.connection.tables.map do |table|
        self[table] ||= []
      end

      self
    end

    def to_sql
      io = StringIO.new
      io.puts <<~SQL_OUTPUT
        --
        -- Redacted export generation SQL
        -- #{Time.zone.now}
        --

        DROP SCHEMA IF EXISTS redacted CASCADE; CREATE SCHEMA redacted;

      SQL_OUTPUT
      sort.each do |table, attributes|
        io.puts <<~SQL_OUTPUT
          CREATE TABLE redacted.#{table} AS (SELECT #{attributes.join ', '} FROM public.#{table});

        SQL_OUTPUT
      end
      io.puts <<~SQL_OUTPUT
        --
        -- Redacted export generation SQL complete
        --
      SQL_OUTPUT
      io.string
    end
  end
end
