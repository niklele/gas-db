require 'sinatra'
require './scraper.rb'
require './bigquery.rb'

get "/" do
  "https://github.com/niklele/gas-db"
end

# get "/scrape" do
#   locations = JSON.parse(File.read('locations.json'))["locations"]
#   Scraper.scrape(locations)
# end

get "/test" do
  begin
    return BigQuery.has_station? 490
  rescue => e
    return e
  end
end