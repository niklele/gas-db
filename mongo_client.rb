require 'dotenv/load'
require 'mongo'
require 'json'
require 'neatjson'
require 'logger'
require 'colorize'

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
    # Turn off debug-mode
    Mongo::Logger.logger.level = Logger::INFO # DEBUG

    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG
    @logger.progname = 'MongoClient'

    begin
      @client = use_local_client ? local_client : remote_client
      @db = @client.database

      # index station_ids in prices
      @db[:prices].indexes.create_one(station_id: Mongo::Index::ASCENDING)
      # TODO indeces on reported, collected, price

      # unique index on price
      @db[:prices].indexes.create_one({station_id: 1,
                                      fuel_type: 1,
                                      payment_type: 1,
                                      price: 1,
                                      reported: 1},
                                      {unique: true, drop_dups: true})

    rescue Exception => err
      @logger.fatal { "#{err}".red }
    end
  end

  def close
    @client.close
  end

  def stations() return @db[:stations] end
  def bootstrap_stations() return @db[:bootstrap_stations] end
  def prices() return @db[:prices] end

  def print_all_stations
    stations = @db[:stations]
    result = stations.find()

    result.each do |doc|
      puts JSON.neat_generate(doc).cyan
    end
  end

  def station_exists?(station_id)
    return @db[:stations].count( :_id => station_id ) > 0
  end

  def most_recent_prices()

    # separate each station
    # sort by reported time
    # take the last one

    # return @db[:prices].aggregate([
    #   {'$group': {
    #     _id: { station_id: "$station_id", fuel_type: "$fuel_type", payment_type: "$payment_type" }
    #   }},
    #   {'$sort': {
    #     _id: { reported: 1 }
    #   }},
    #   {'$group': {
    #     _id: '$_id',
    #     doc: { '$last': '$$ROOT' }
    #   }}
    # ])

    res = @db[:prices].aggregate([
      {'$sort': { station_id: 1, reported: 1 }}, 
      {'$limit': 100 },
      {'$group': {
        _id: { station_id: "$station_id" },
        doc: { '$push': '$$ROOT' }
      }}
    ])

    return res
  end

  def average_price_by_type()
    # avg_image_search_time = @coll.aggregate([ {"$group" => {"_id"=>"$type", "avg"=> {"$avg"=>"$time_elapsed"}}}, {"$match" => {"_id"=>"image_search"}} ]).first['avg']

    # take the most recent price from each type for each station before averaging
    sort = {
      '$sort': { 'station_id': 1, 'collected': 1, 'reported': 1 }
    }

    station_group = {
      '$group': {
        _id: ''
      }
    }

    # group by fuel type and payment type
    typeGroup = {
      '$group': {
        _id: { "fuel_type": "$fuel_type", "payment_type": "$payment_type" },
        total_count: { "$sum": 1 }, # count number of each
        most_recent_price_time: { '$last': '$reported' },
        avg_price: { "$avg": "$most_recent_price" } # take the average of each "most_recent_price" and return it as "avg_price"
      }
    }

    # statsGroup = {
    #   '$group': {
    #     _id: { "fuel_type": "$fuel_type", "payment_type": "$payment_type" },
    #     avg_price: { "$avg": "$most_recent_price" } # take the average of each "most_recent_price" and return it as "avg_price"
    #   }
    # }


    return @db[:prices].aggregate([sort, typeGroup])
  end

  # def station_data_ok?(data)
  #   # check that required fields exist
  #   # TODO figure out which ones
  #   ok = true
  #   ok &= data.key? :location
  #   ok &= data.key? :name
  #   ok &= data.key? :address
  #   ok &= data.key? :latitude
  #   ok &= data.key? :longitude
  #   ok &= data.key? :phone
  #   ok &= data.key? :working
  #   ok &= data.key? :url
  #   ok &= data.key? :legacy_url
  #   ok &= data.key? :website_nearby_stations
  #   ok &= data.key? :nearby_stations
  #   ok &= data.key? :features
  #   return ok
  # end

  def insert(collection, data)
    begin
      @db[collection].insert_one(data)
    rescue Exception => err
      @logger.warn { "Cannot insert to #{@db[collection].namespace} | #{err}".red }
    end
  end

  # def insert(collection, data)
  #   begin
  #     collection.insert_one(data)
  #   rescue Exception => err
  #     @logger.warn { "Cannot insert to #{collection.namespace} | #{err}".red }
  #   end
  # end

  def insert_many(collection, data)
    begin
      collection.insert_many(data)
    rescue Exception => err
      @logger.warn { "Cannot insert many to #{collection.namespace} | #{err}".red }
    end
  end

  def insert_station(data) insert(:stations, data) end
  def insert_bootstrap_station(data) insert(:bootstrap_stations, data) end
  def insert_price(data) insert(:prices, data) end
  def insert_many_prices(data) insert_many(:prices, data) end

  def update(collection, id, update)
    # update is the mongo update statement
    begin
      @db[collection].find_one_and_update({ _id: id}, update)
    rescue Exception => err
      @logger.warn { "Cannot update #{@db[collection].namespace} id: #{id} | #{err}".red }
    end
  end

  def update_station(id, update) update(:stations, id, update) end
  # def update_price(id, update) update(@db[:prices], id, update) end

  def delete(collection, id)
    begin
      @db[collection].find_one_and_delete({ _id: id})
    rescue Exception => err
      @logger.warn { "Cannot delete #{@db[collection].namespace} id: #{id} | #{err}".red }
    end
  end

  def delete_old_prices(threshold)
    # delete prices collected before the threshold
    begin
      @db[:prices].delete_many({collected: {"$lte": threshold} })
    rescue Exception => err
      @logger.warn { "Cannot delete old prices | #{err}".red }
    end
  end

  def delete_station(id) delete(:stations, id) end
  def delete_price(id) delete(:prices, id) end

  def delete_all(collection)
    begin
      @db[collection].delete_many()
    rescue Exception => err
      @logger.warn { "Cannot delete all from #{@db[collection].namespace} | #{err}".red }
    end
  end

  def delete_all_stations() delete_all(:stations) end
  def delete_all_prices() delete_all(:prices) end

  def set_station_working(station_id, working)
    # set 'working' var
    update_station(station_id, {"$set" => { working: working }})
  end

  def lookup_station(price_id)
    begin
      priceDoc = @db[:prices].find( _id: price_id ).first
      return @db[:stations].find( _id: priceDoc[:station_id] ).first
    rescue Exception => err
      @logger.warn { "Cannot lookup station for price with id: #{price_id} | #{err}".red }
    end
  end

  def test_station
    testStation = {
        _id: 999999999, # real station_id is 12361
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
    return testStation
  end

  def test_price
    testPrice = {
      _id: 1, # TODO autoincrementing or ObjectID?
      station_id: 999999999, # parent referencing
      collected: Time.new(),
      reported: Time.new(),
      type: "regular",
      price: 3.3,
      user: "example_user",
    }
    return testPrice
  end

end

def test_mongo_client()

  MongoClient.open(false) do |mc|

    # TODO test with multiple price records

    # mc.insert_station(mc.test_station)
    # mc.print_all_stations

    # mc.insert_price(mc.test_price)
    # station = mc.lookup_station(1)
    # puts JSON.neat_generate(station).yellow

    # mc.insert_station(mc.test_station)
    # mc.print_all_stations

    # puts mc.station_exists? 999999999

    # mc.set_station_working(999999999, false)
    # mc.print_all_stations

    # mc.delete_station 999999999
    # mc.print_all_stations

    # mc.delete_price 1

    mc.average_price_by_type.each do |x|
      puts JSON.neat_generate(x)
    end

  end
end

# test_mongo_client()

