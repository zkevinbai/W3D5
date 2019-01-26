require_relative 'db_connection'
require 'active_support/inflector'
require "byebug"
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ...
    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT 
        * 
      FROM
        #{self.table_name}
      SQL
    .first.map {|k| k.to_sym}
  end

  def self.finalize!

    self.columns.each do |col|
      define_method(col) do 
        self.attributes[col]
        # instance_variable_get("@#{col}")
      end

      define_method("#{col}=") do |v|
        self.attributes[col] = v
        # instance_variable_set("@#{col}", v)
      end
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # ...
    @table_name ||= self.to_s.tableize
  end

  def self.all
    # ...
    parse_all(DBConnection.execute(<<-SQL)
      SELECT 
        *
      FROM
        #{self.table_name}
      SQL
      )
  end

  def self.parse_all(results)
    objects = []
    results.each do |row|
      objects << self.new(row)
    end
    objects
    # ...
  end

  def self.find(id)
    # ...
    self.all.each do |object|
      return object if object.id == id
    end
    nil
  end

  def initialize(params = {})
    # ...
    params.each do |k, v|
      col = k.to_sym
      raise "unknown attribute '#{k}'" unless self.class.columns.include?(col)
        
      self.send("#{col}=", v)
    end
  end

  def attributes
    # ...
    @attributes ||= Hash.new
  end

  def attribute_values
    # ...
    self.attributes.values
  end

  
  def insert
    # ...
    col_names = self.class.columns[1..-1].join(',')
    question_marks = (['?']*self.class.columns[1..-1].length ).join(',')
    
    # debugger
    DBConnection.execute(<<-SQL, *self.attribute_values)
      INSERT INTO #{self.class.table_name} 
        (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.attributes[:id] = DBConnection.last_insert_row_id
  end

  def update
    set_line = self.class.columns[1..-1].map {|col| "#{col} = ?"}.join(',')
    id = self.attributes[:id]
    # debugger
    DBConnection.execute(<<-SQL, *self.attribute_values)
      UPDATE #{self.class.table_name}
      SET
        (#{set_line})
      WHERE
        id = #{id}
    SQL

    # ...
  end

  def save
    # ...
  end
end
