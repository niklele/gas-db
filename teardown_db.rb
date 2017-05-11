require 'sequel'
require 'pg'
require 'dotenv/load'

DB = Sequel.connect(ENV['DATABASE_URL'])

if DB.table_exists?(:prices)
    puts 'tearing down prices table'
    DB.drop_table :prices
end

if DB.table_exists?(:stations)
    puts 'tearing down stations table'
    DB.drop_table :stations
end
