require 'sequel'
require 'pg'
require 'dotenv/load'

DB = Sequel.connect(ENV['DATABASE_URL'])

class GasDB

    def self.setup()
        create_stations()
        create_prices()
    end

    def self.teardown()
        teardown_prices()
        teardown_stations()
    end

    def self.summary()
        puts "#{DB[:stations].count} stations"
        puts "#{DB[:prices].count} prices"

        oldest = DB['select * from prices order by reported asc limit 1'].first[:reported]
        newest = DB['select * from prices order by reported desc limit 1'].first[:reported]

        puts "oldest price reported at #{oldest}"
        puts "newest price reported at #{newest}"
    end

    private

    def self.create_stations()
        if !DB.table_exists?(:stations)
            puts 'creating stations table'
            DB.create_table :stations do
                Integer :station_id, :primary_key => true
                String :location
                String :name
                String :address
                String :phone
                # todo features
                unique [:station_id, :name, :address, :phone]
            end
        end
    end

    def self.create_prices()
        if !DB.table_exists?(:prices)
            puts 'creating prices table'
            DB.create_table :prices do
                foreign_key :station_id, :stations
                Time :collected
                Time :reported
                String :type
                Float :price
                String :user
                # not unique on time collected so that we only get updated prices
                unique [:station_id, :reported, :type, :price, :user]
            end
        end
    end

    def self.teardown_prices()
        if DB.table_exists?(:prices)
            puts 'tearing down prices table'
            DB.drop_table :prices
        end
    end

    def self.teardown_stations()
        if DB.table_exists?(:stations)
            puts 'tearing down stations table'
            DB.drop_table :stations
        end
    end

end