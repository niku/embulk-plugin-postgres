module Embulk
  require "jdbc/postgres"
  Jdbc::Postgres.load_driver

  class OutputPostgres < OutputPlugin
    Plugin.register_output("postgres", self)

    def self.transaction(config, schema, processor_count, &control)
      task = {
        "host"     => config.param("host",     :string),
        "port"     => config.param("port",     :integer, default: 5432),
        "username" => config.param("username", :string),
        "password" => config.param("password", :string,  default: ""),
        "database" => config.param("database", :string),
        "table"    => config.param("table",    :string)
      }
      yield(task)
      return {}
    end

    def self.connect(task)
      url = "jdbc:postgresql://#{task['host']}:#{task['port']}/#{task['database']}"
      props = java.util.Properties.new
      props.put("user", task["username"])
      props.put("password", task["password"])

      pg = org.postgresql.Driver.new.connect(url, props)
      if block_given?
        begin
          yield pg
        ensure
          pg.close
        end
      end
      pg
    end

    def initialize(task, schema, index)
      super
      @pg = self.class.connect(task)
    end

    def close
      @pg.close
    end

    def add(page)
      prep = @pg.prepareStatement(statement)
      page.each do |record|
        record.each.with_index(1) do |column, index|
          prep.setString(index, column.to_s)
        end
        prep.execute
      end
    ensure
      prep.close
    end

    def statement
      table = task["table"]
      columns = schema.map(&:name).join(",")
      values_placeholder_with_type = schema.map(&:type).map { |type| "?::#{EMBULK_TO_POSTGRES[type]}" }.join(",")
      %Q[insert into "#{table}" (#{columns}) values (#{values_placeholder_with_type})]
    end

    # see Embulk::Type in the embulk repository
    # lib/embulk/column.rb
    EMBULK_TO_POSTGRES = {
      boolean: "boolean",
      long: "integer",
      double: "double precision",
      string: "varchar",
      timestamp: "timestamp"
    }
  end
end
