require_relative 'db_connection'
require_relative '01_sql_object'
require 'byebug'
module Searchable
  def where(params)
     results = DBConnection.execute(<<-SQL, params.values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_line(params)}
    SQL
    parse_all(results)
  end

  def where_line(params)
    params.map { |k, v| "#{k} = ?"}.join(' AND ').chomp(' AND ')
  end
end

class SQLObject
  extend Searchable
end
