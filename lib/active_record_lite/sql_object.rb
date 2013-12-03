require 'active_support/inflector'

require_relative './associatable'
require_relative './db_connection' # use DBConnection.execute freely here.
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject
  # sets the table_name
  def self.set_table_name(table_name)
    @table_name = table_name
  end

  # gets the table_name
  def self.table_name
    @table_name || self.name.underscore.pluralize
  end

  # querys database for all records for this type. (result is array of hashes)
  # converts resulting array of hashes to an array of objects by calling ::new
  # for each row in the result. (might want to call #to_sym on keys)
  def self.all
    results = DBConnection.execute(<<-SQL, id)
      SELECT * 
      FROM #{table_name}
      WHERE id = ?
    SQL
    
    parse_all(results).first
  end

  # querys database for record of this type with id passed.
  # returns either a single object or nil.
  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
    SELECT *
    FROM #{table_name}
    WHERE id = ?
    SQL
    
    parse_all(results).first 
  end

  # executes query that creates record in db with objects attribute values.
  # use send and map to get instance values.
  # after, update the id attribute with the helper method from db_connection
  
  def attribute_values
    self.class.attributes.map { |attribute| self.send(:attribute) }
  end
  
  def create
    attribute_names = self.class.attributes.join(", ")
    question_marks = (['?'] * self.class.attributes.count).join(", ")
     
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO 
      (#{self.table_name}) (#{attribute_names})
    VALUES 
      (#{question_marks})
      SQL
    
    self.id = DBConnection.last_insert_row_id
  end

  # executes query that updates the row in the db corresponding to this instance
  # of the class. use "#{attr_name} = ?" and join with ', ' for set string.
  def update
    set_attr = self.class.attributes.map { |attr| "#{attr} = ?" }.join(", ") 
    
    DBConnection.execute(<<-SQL, *attribute_values)
    UPDATE #{self.class.table_name}
    SET #{set_attr}  
    WHERE id = ? 
    SQL
  end

  # call either create or update depending if id is nil.
  def save
    if id.nil?
      create
    else
      update
    end
  end

end
