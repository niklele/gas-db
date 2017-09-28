require 'dotenv/load'
require 'mongo'
require 'json'
require 'neatjson'

# Turn off debug-mode
# Mongo::Logger.logger.level = Logger::WARN

class MongoClient

  def self.open(*args)
     mongo_client = new(*args)
     begin
       yield mongo_client
     ensure
       mongo_client.close
     end
  end

  def close
    @client.close
  end

  def local_client
    mongo_uri = ENV['LOCAL_MONGODB_URI']
    client = Mongo::Client.new([mongo_uri], :database => 'gasDB-test' );
    return client
  end

  def remote_client
    mongo_uri = ENV['MLAB_MONGODB_URI']
    client = Mongo::Client.new(mongo_uri);
    return client
  end

  def initialize(use_local_client=false)

    begin
      @client = use_local_client ? local_client : remote_client
      @db = @client.database

    rescue Exception => err
      puts("Error: #{err}")
    end

  end

  def print_all_stations
    stations = @db[:stations]
    result = stations.find()

    result.each do |doc|
      puts JSON.neat_generate(doc)
    end
  end

  def station_exists?(station_id)
    return @db[:stations].count( :station_id => station_id ) > 0
  end

  def station_data_ok?(data)
    # check that required fields exist
    # TODO figure out which ones
    ok = true
    ok &= data.key? :location
    ok &= data.key? :name
    ok &= data.key? :address
    ok &= data.key? :latitude
    ok &= data.key? :longitude
    ok &= data.key? :phone
    ok &= data.key? :working
    ok &= data.key? :url
    ok &= data.key? :legacy_url
    ok &= data.key? :website_nearby_stations
    ok &= data.key? :nearby_stations
    ok &= data.key? :features
    return ok
  end

  def add_station(station_id, data) # unique insert
    puts "TODO"
  end

  def update_station(station_id, data)
    puts "TODO"
  end

  def set_station_working(station_id, working)
    # set 'working' var
    puts "TODO"
  end

  def delete_station(station_id)
    puts "TODO"
  end

  def test_station
    testStation = { station_id: 12361,
        location: 'Cupertino',
        name: 'Valero',
        address: '705 San Antonio Rd Palo Alto, CA 94303, USA',
        latitude: 37.416733,
        longitude: -122.1036,
        phone: '650-494-7242',
        working: true,
        url: 'https://www.gasbuddy.com/Station/12361',
        legacy_url: '',
        website_nearby_stations: [4111, 1922, 5443, 5022, 5023],
        nearby_stations: [],
        features: ['C-Store', 'Pay At Pump', 'Restrooms', 'Air', 'Open 24/7', 'Has Fuel', 'Has Power']
    }
  end

end


MongoClient.open(true) do |mc|
  mc.print_all_stations
  puts mc.station_exists? 12361
end

