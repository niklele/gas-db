require "dotenv/load"
require "google/cloud/bigquery"

class BigQuery

  @client = Google::Cloud::Bigquery.new
  @dataset = @client.dataset "gasdb"

  def self.create_stations
    puts "creating table: 'stations'"
    begin
      table = @dataset.create_table "stations" do |schema|
        schema.integer "station_id", mode: :required
        schema.string "location", mode: :required
        schema.string "name", mode: :required
        schema.string "address", mode: :nullable
        schema.string "phone", mode: :nullable
        schema.float "latitude", mode: :required
        schema.float "longitude", mode: :required
        schema.string "url", mode: :required
      end
      table.description = "information about each station"
    rescue Exception => e
      puts "Error: #{e}"
    end
  end

  def self.create_prices
    puts "creating table: 'prices'"
    begin
      table = @dataset.create_table "prices" do |schema|
        schema.timestamp "collected", mode: :required
        schema.timestamp "reported", mode: :required
        schema.integer "station_id", mode: :required
        schema.float "price", mode: :required
        schema.string "type", mode: :required
        schema.string "user", mode: :required
      end
      table.description = "fuel prices for all stations"
    rescue Exception => e
      puts "Error: #{e}"
    end
  end

  def self.delete_stations
    begin
      puts "Deleting table: 'stations'"
      table = @dataset.table "stations"
      table.delete
    rescue Exception => e
      puts "Error: #{e}"
    end
  end

  def self.delete_prices
    begin
      puts "Deleting table: 'prices'"
      table = @dataset.table "prices"
      table.delete
    rescue Exception => e
      puts "Error: #{e}"
    end
  end

  def self.stations
    return @dataset.table "stations"
  end

  def self.prices
    return @dataset.table "prices"
  end

  # checks whether a given station is in the table
  def self.has_station?(station_id)
    count_sql = "select count(*) from #{self.stations.query_id} where station_id = #{station_id}"
    res = @client.query count_sql
    return (res.first.values.first >= 1)
  end

end
