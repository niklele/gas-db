require 'dotenv/load'
require 'sinatra'
require './mongo_client'

get '/' do
  res = []
  MongoClient.open do |mc|
    res = mc.average_price_by_type()
  end

  averages = {
    regular_cash: res.select{ |a| a[:_id] == {"fuel_type"=>"regular", "payment_type"=>"cash"}}.first,
    regular_credit: res.select{ |a| a[:_id] == {"fuel_type"=>"regular", "payment_type"=>"credit"}}.first,
    midgrade_cash: res.select{ |a| a[:_id] == {"fuel_type"=>"midgrade", "payment_type"=>"cash"}}.first,
    midgrade_credit: res.select{ |a| a[:_id] == {"fuel_type"=>"midgrade", "payment_type"=>"credit"}}.first,
    premium_cash: res.select{ |a| a[:_id] == {"fuel_type"=>"premium", "payment_type"=>"cash"}}.first,
    premium_credit: res.select{ |a| a[:_id] == {"fuel_type"=>"premium", "payment_type"=>"credit"}}.first,
    diesel_cash: res.select{ |a| a[:_id] == {"fuel_type"=>"diesel", "payment_type"=>"cash"}}.first,
    diesel_credit: res.select{ |a| a[:_id] == {"fuel_type"=>"diesel", "payment_type"=>"credit"}}.first,
  }

  erb :index, {locals: {averages: averages}}
end

get '/map' do
  erb :map
end

get '/station/:station_id' do
  sid = Integer(params['station_id'])
  station = nil
  MongoClient.open do |mc|
    station = mc.stations.find(_id: sid).first
  end
  if station.nil?
    "Station #{sid} not found"
  else
    erb :station, {locals: {station: station}}
  end
end