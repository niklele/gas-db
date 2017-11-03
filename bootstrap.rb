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

def random_coords(center_lat, center_lng, max_radius, n_samples)
  # pick r from [0, max_radius ^ 2]
  # pick theta from [0, 2 pi]

  rng = Random.new
  rad2 = max_radius ** 2

  samples = []
  for i in 0..n_samples
    r = rng.rand(rad2)
    theta = rng.rand(2 * Math::PI)

    lat = Math.sqrt(r) * Math.sin(theta) + center_lat
    lng = Math.sqrt(r) * Math.cos(theta) + center_lng

    samples << [lat, lng]
  end

  return samples

end

def bootstrap_stations(coords)

  MongoClient.open do |mc|
    coords.each do |lat, lng|
      res = Scraper.parse_nearby(lat, lng)

      if res.any?
        puts JSON.neat_generate(res).green
        res.each do |sid|
          mc.insert_bootstrap_station({_id: sid})
        end
      end

    end
  end
end

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

def bootstrap()
  # center = [37.4, -122.1]

  # coords = [37.297807, -122.541690] # pacific ocean
  coords = [37.55, -122.17] # middle of the bay

  # 0.33, -0.42 # max differences in lat/lng
  radius = 0.1089 # lat/long units

  n_samples = 500

  # puts JSON.neat_generate(random_coords(radius, n_samples))

  coords = random_coords(coords[0], coords[1], radius, n_samples)
  bootstrap_stations(coords)
end

bootstrap()
