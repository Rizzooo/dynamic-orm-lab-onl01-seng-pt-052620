require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end 
  
  def self.column_names
    #DB[:conn].results_as_hash = true
    
    sql = "PRAGMA table_info ('#{table_name}')"
    
    table_info = DB[:conn].execute(sql)
    column_names = []
    
    table_info.each do |column|
      column_names << column["name"]
    end 
    column_names.compact
  end
  
  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end
  
  def initialize(objects={})
    objects.each do |prop, v|
      self.send("#{prop}=", v)
    end
  end
  
  def table_name_for_insert
    self.class.table_name
  end
  
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end
  
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end
  
  def save
    DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (?)", [values_for_insert])
    
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end
  
  def self.save
    save
  end
  
  def find_by_name(name)
    DB[:conn].execute("SELECT * FROM #{table_name_for_insert} WHERE name = ?", [name])
  end
  
  def find_by(attribute)
    column = attribute.keys[0]
    value = attribute.values[0]
    
    sql = <<-SQL 
      SELECT * FROM #{table_name} 
      WHERE #{column} = ?
    SQL
    
    DB[:conn].execute(sql, value)
  end
end