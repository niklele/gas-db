require 'dotenv/load'
require 'mongo'
require 'json'
require 'neatjson'

# Turn off debug-mode
# Mongo::Logger.logger.level = Logger::WARN

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

begin
  # client = local_client
  client = remote_client

  db = client.database
  # db.collection_names.each{|name| puts name }

  stations = db[:stations]

  result = stations.find()
  # result = stations.find(station_id: 12361)

  result.each do |doc|
    puts JSON.neat_generate(doc)
  end


  # testStation = { station_id: 12361,
  #     location: 'Cupertino',
  #     name: 'Valero',
  #     address: '705 San Antonio Rd Palo Alto, CA 94303, USA',
  #     latitude: 37.416733,
  #     longitude: -122.1036,
  #     phone: '650-494-7242',
  #     working: true,
  #     url: 'https://www.gasbuddy.com/Station/12361',
  #     legacy_url: '',
  #     website_nearby_stations: [4111, 1922, 5443, 5022, 5023],
  #     nearby_stations: [],
  #     features: ['C-Store', 'Pay At Pump', 'Restrooms', 'Air', 'Open 24/7', 'Has Fuel', 'Has Power']
  # }

  # result = stations.insert_one(testStation)
  # puts result.n

  # puts stations.find( { station_id: 12361 } ).first

  # TODO unique insert

  client.close

rescue StandardError => err
  puts("Error: #{err}")

end