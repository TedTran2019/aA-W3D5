require_relative '03_associatable'

# Phase IV

=begin
YOUR CLASS: Cat
has_one_through :home,
through: :human, # cat has a human association, can look in assoc_options 
source: :house   # cat doesn't have house assoc--human does.
=end
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) {
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      target = source_options.table_name
      from = through_options.table_name
      result = DBConnection.execute(<<-SQL, self.send(through_options.foreign_key))
        SELECT
          #{target}.*
        FROM
          #{from}
        JOIN
          #{target} ON #{from}.#{source_options.foreign_key} = #{target}.#{source_options.primary_key}
        WHERE
          #{from}.#{through_options.primary_key} = ?
      SQL
      result.empty? ? nil : source_options.model_class.new(result.first)
    }

    # define_method(name) {
    #   self.send(through_name).send(source_name)
    # }
  end
end
