# require './db.rb'
require 'json'
require './bigquery.rb'
require './scraper.rb'

desc 'create BigQuery tables'
task :setup do
    BigQuery.create_stations
    BigQuery.create_prices
end

desc 'delete BigQuery data'
task :delete do
    STDOUT.puts "WARNING This will delete all BigQuery data. Do you wish to continue? (Y/N)"
    input = STDIN.gets.strip
    if input.match /y/i
        BigQuery.delete_stations
        BigQuery.delete_prices
    end
end

# desc 'print db summary info'
# task :summary do
#     GasDB::summary()
# end

# desc 'copy prices data into a csv file'
# task :copy do
#     GasDB::copy()
# end

# desc 'move prices data into a csv file'
# task :move do
#     GasDB::move()
# end

# desc 'move prices data into a csv file which is uploaded to dropbox'
# task :dropbox_move do
#     GasDB::dropbox_move()
# end

desc 'run scraper'
task :scrape do
    locations = JSON.parse(File.read('locations.json'))["locations"]
    Scraper.scrape(locations)
end
