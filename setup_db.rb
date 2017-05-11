require 'sequel'
require 'pg'
require 'dotenv/load'

DB = Sequel.connect(ENV['DATABASE_URL'])

if !DB.table_exists?(:stations)
    puts 'creating stations table'
    DB.create_table :stations do
        Integer :station_id, :primary_key => true
        String :name
        String :address
        String :phone
        # todo features
        unique [:station_id, :name, :address, :phone]
    end
end

if !DB.table_exists?(:prices)
    puts 'creating prices table'
    DB.create_table :prices do
        foreign_key :station_id, :stations
        Time :collected
        Time :reported
        String :type
        Float :price
        String :user
        unique [:station_id, :collected, :reported, :type, :price, :user]
    end
end