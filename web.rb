require 'dotenv/load'
require 'sinatra'
require './mongo_client'

get '/' do
  erb :map
end

get '/station/:station_id' do
  sid = Integer(params['station_id'])
  station = nil
  MongoClient.open do |mc|
    station = mc.stations.find(:_id => sid).first
  end
  if station.nil?
    "Station #{sid} not found"
  else
    erb :station, :locals => {:station => station}
  end
end