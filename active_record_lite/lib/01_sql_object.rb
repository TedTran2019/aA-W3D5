require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.
require 'byebug'

class SQLObject
  def self.columns
    return @columns if @columns
    @columns = DBConnection.execute2(<<-SQL).first
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    @columns.map! { |col| col.to_sym }
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) { attributes[col] }
      define_method("#{col}=") { |val| attributes[col] = val }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
    @table_name
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL).first
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = #{id}
    SQL
    result.nil? ? nil : self.new(result)
  end

  def initialize(params = {})
    cols = self.class.columns
    params.each do |k, v|
      key_sym = k.to_sym
      raise "unknown attribute '#{k}'" unless cols.include?(key_sym)
    end
    params.each { |k, v| self.send("#{k.to_sym}=", v) }
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |name| self.send(name) }
  end

  # Why not use attributes.values? Because it skips over the nil value?
  def insert
    values = attribute_values[1..-1]
    DBConnection.execute(<<-SQL, *values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks(values.length)})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    values = attribute_values[1..-1]
    values << self.id
    DBConnection.execute(<<-SQL, *values)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_names}
      WHERE
        id = ?
    SQL
  end

  def save
    self.id.nil? ? insert : update
  end

  private 

  def set_names
    self.class.columns[1..-1].map { |name| "#{name} = ?"}.join(',').chomp(',')
  end

  def col_names
    self.class.columns[1..-1].join(',').chomp(',')
  end 

  def question_marks(n)
    (["?"] * n).join(',').chomp(',')
  end
end
