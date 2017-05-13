require 'sequel'
require 'pg'
require 'csv'
require 'dotenv/load'
require './dropbox.rb'

DB = Sequel.connect(ENV['DATABASE_URL'])

class GasDB

    def self.setup()
        create_stations()
        create_prices()
    end

    def self.teardown()
        teardown_table(:prices)
        teardown_table(:stations)
        delete_csv()
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

        csvFiles = DropboxClient::csvList()
        puts "#{csvFiles.count} csv files in Dropbox"
    end

    def self.copy()
        puts 'copying data from prices table to prices.csv'
        prices = DB[:prices].all
        CSV.open('prices.csv', 'w') do |csv|
            csv << [:station_id, :collected, :reported, :type, :price, :user]
            prices.each do |row|
                csv << [row[:station_id],
                        row[:collected],
                        row[:reported],
                        row[:type],
                        row[:price],
                        row[:user]]
            end
        end
    end

    def self.move()
        copy()
        puts 'deleting data from prices'
        DB['delete from prices'].delete
    end

    def self.dropbox_move()
        move()
        DropboxClient::uploadPrices()
        delete_csv()
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
            puts 'creating :prices table'
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

    def self.teardown_table(t_name)
        if DB.table_exists?(t_name)
            puts "tearing down #{t_name} table"
            DB.drop_table(t_name)
        end
    end

    def self.delete_csv()
        puts 'deleting all csv files'
        Dir.glob("#{Dir.pwd}/*.csv").each { |file| File.delete(file) }
    end

end