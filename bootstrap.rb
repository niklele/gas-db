require 'dotenv/load'
require 'logger'
require 'colorize'
require 'neatjson'
require 'google_maps_service'
require './scrape.rb'

###
# The goal is to make a list of station ids that will be scraped
# 1. generate a list of lat,lng to query for nearby stations
# 2. use nearby stations to get more nearby stations


center = [37.4, -122.1]
radius = 70 # km

coords = [37.297807, -122.541690] # pacific ocean

res = Scraper.parse_nearby(coords[0], coords[1])
puts JSON.neat_generate(res).blue


def find_address()
  # This can be deferred to later

  gmaps = GoogleMapsService::Client.new(
    key: ENV['GMAPS_KEY'],
    retry_timeout: 20,
    queries_per_second: 10
  )

  # Valero station 12361
  coords = [37.416733, -122.1036]

  results = gmaps.reverse_geocode(coords)

  # puts JSON.neat_generate(results[0]).green

  address = results[0][:formatted_address]
  puts address

end