require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key]
    @class_name = options[:class_name]
    @primary_key = options[:primary_key]
    single = name.to_s.singularize
    @foreign_key ||= "#{single}_id".to_sym
    @class_name ||= single.capitalize
    @primary_key ||= :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key]
    @class_name = options[:class_name]
    @primary_key = options[:primary_key]
    @foreign_key ||= "#{self_class_name.underscore}_id".to_sym
    @class_name ||= name.to_s.singularize.capitalize
    @primary_key ||= :id
  end
end

=begin
  YOU ARE: Person class
  belongs_to :house, 
  foreign_key: :house_id, 
  primary_key: :id,
  class_name: "House"

  YOU ARE: House class
  has_many :people,
  foreign_key: :house_id, 
  primary_key: :id,
  class_name: "Person"
=end

module Associatable
  # Phase IIIb
  # belongs_to is a class method through extend Module that uses 
  # define_method to create instance methods
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method(name) { 
      results = DBConnection.execute(<<-SQL, self.send(options.foreign_key))
        SELECT
          #{options.table_name}.*
        FROM
          #{options.table_name}
        WHERE
          #{options.primary_key} = ?
      SQL
      results.empty? ? nil : options.model_class.new(results.first)
    }
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    define_method(name) {
      results = DBConnection.execute(<<-SQL, self.send(options.primary_key))
        SELECT
          #{options.table_name}.*
        FROM
          #{options.table_name}
        WHERE
          #{options.foreign_key} = ?
      SQL
      results.map { |result| options.model_class.new(result) }
    }
  end

  def assoc_options
    @options ||= {}
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
