require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true
        sql = "pragma table_info('#{table_name}')"
        table_info = DB[:conn].execute(sql)
        column_names = []

        table_info.each do |column|
            column_names << column["name"]
        end
        column_names.compact
    end

    def initialize(options={})
        options.each do |property, value|
            self.send("#{property}=", value)
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
        sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
        #binding.pry
    end

    def self.find_by_name(name)
        DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", [name])
    end

    def self.find_by(attribute)
        value = attribute.values.first #.values creates an array of all the values in a hash
        new_value = value.class == Fixnum ? value : "'#{value}'" #if value is a Fixnum, return the num which
        #will be equal to value. otherwise, value will be a string captured by interpolation
        sql = "SELECT * FROM #{self.table_name} WHERE #{attribute.keys.first} = #{new_value}"
        #.keys creates an array of all the keys in a hash
        DB[:conn].execute(sql)
        #binding.pry
    end

end