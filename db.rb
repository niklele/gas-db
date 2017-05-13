require 'sequel'
require 'pg'
require 'dotenv/load'

DB = Sequel.connect(ENV['DATABASE_URL'])

class GasDB

    def self.setup()
        create_stations()
        create_prices(:prices)
    end

    def self.teardown()
        prices_tables().each{ |t| teardown_table(t) }
        teardown_table(:stations)
    end

    def self.summary()
        puts "#{DB[:stations].count} stations"
        puts "#{DB[:prices].count} prices"

        oldest = DB['select * from prices order by reported asc limit 1'].first[:reported]
        newest = DB['select * from prices order by reported desc limit 1'].first[:reported]
        diff = Time.at(newest - oldest).utc.strftime("%T")

        puts "oldest price reported at #{oldest}"
        puts "newest price reported at #{newest}"
        puts "time difference: #{diff}"
    end

    def self.copy()
        # count number of tables with 'prices' in the name
        count = prices_tables().count
        new_prices = "prices_#{count}"

        puts "copying data from prices to #{new_prices}"
        DB.run("select * into #{new_prices} from prices")
    end

    def self.move()
        copy()
        puts 'deleting data from prices'
        DB['delete from prices'].delete
    end

    private

    def self.prices_tables()
        table_query = "select table_name from information_schema.tables "\
                      "where table_schema='public' and table_type='BASE TABLE' "\
                      "and table_name like 'prices%'"

        return DB[table_query].map{ |e| e[:table_name] }
    end

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

    def self.create_prices(t_name)
        if !DB.table_exists?(t_name)
            puts "creating #{t_name} table"
            DB.create_table t_name do
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

    def self.teardown_table(t_name)
        if DB.table_exists?(t_name)
            puts "tearing down #{t_name} table"
            DB.drop_table(t_name)
        end
    end

end