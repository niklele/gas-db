require 'dotenv/load'
require 'logger'
require 'colorize'
require 'neatjson'
require 'google_maps_service'
require 'parallel'
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

# def find_address()
#   # This can be deferred to later

#   gmaps = GoogleMapsService::Client.new(
#     key: ENV['GMAPS_KEY'],
#     retry_timeout: 20,
#     queries_per_second: 10
#   )

#   # Valero station 12361
#   coords = [37.416733, -122.1036]

#   results = gmaps.reverse_geocode(coords)

#   # puts JSON.neat_generate(results[0]).green

#   address = results[0][:formatted_address]
#   puts address

# end

def init_bootstrap_stations()
  # center = [37.4, -122.1]
  # coords = [37.297807, -122.541690] # pacific ocean
  coords = [37.55, -122.17] # middle of the bay

  # 0.33, -0.42 # max differences in lat/lng
  radius = 0.1089 # lat/long deg
  n_samples = 500

  # puts JSON.neat_generate(random_coords(radius, n_samples))
  coords = random_coords(center_lat, center_lng, radius, n_samples)
  bootstrap_stations(coords)
end

# use oldstations.txt to populate bootstrap stations
def oldstations_bootstrap()
  MongoClient.open do |mc|
    File.foreach("oldstations.txt") do |line|
      sid = Integer(line.strip())
      # puts JSON.neat_generate({_id: sid})
      mc.insert_bootstrap_station({_id: sid})
    end
  end
end

$seeds = [
  [37.258594, -122.017908],
  [37.312663, -121.865138],
  [37.268587, -121.852067],
  [37.249484, -121.812025],
  [37.307207, -121.783772],
  [37.345721, -121.806501],
  [37.403268, -121.863390],
  [37.468917, -121.913911],
  [37.573620, -122.040585],
  [37.769889, -122.253065],
  [37.817572, -122.264773],
  [37.823545, -122.225898],
  [37.848447, -122.265155],
  [37.882748, -122.275321],
  [37.759735, -122.411997],
  [37.785172, -122.424965],
  [37.796840, -122.406784],
  [37.782505, -122.466148],
  [37.774424, -122.488714],
  [37.750893, -122.483721]
]

def seeds_bootstrap()

  radius = 0.02
  n_samples = 30
  MongoClient.open do |mc|
    $seeds.each do |lat, lng|

      coords = random_coords(lat, lng, radius, n_samples)
      Parallel.each(coords, in_threads: 8) do |lat, lng|
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
end

def stations_from_bootstrap()
  # go through bootstrap_stations and parse station for each

  stations = []
  MongoClient.open do |mc|
    mc.bootstrap_stations.find.each do |doc|
      stations << doc[:_id]
    end
  end

  # TODO clean up this function signature
  Scraper.parse_stations(stations, false, false)

end


def resample_bootstrap_stations()

  locations = []
  MongoClient.open do |mc|
    mc.stations.find.each do |doc|
      locations << [doc[:latitude], doc[:longitude]]
    end

    radius = 0.01 # lat/long deg
    n_samples = 5

    Parallel.each(locations, in_threads: 8) do |center_lat, center_lng|
      center_lat = Float(center_lat)
      center_lng = Float(center_lng)

      coords = random_coords(center_lat, center_lng, radius, n_samples)

      # add center explicitly
      coords << [center_lat, center_lng]

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
end



####### 1
# init_bootstrap_stations()
# oldstations_bootstrap()
# seeds_bootstrap()

####### 2
# stations_from_bootstrap()

####### 3
# resample_bootstrap_stations()

# Repeat 2 and 3

