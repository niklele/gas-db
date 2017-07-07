require "dotenv/load"
require "google/cloud/bigquery"

$fuel_type = [
    'regular',
    'midgrade',
    'premium',
    'diesel'
]

class BigQuery

  @client = Google::Cloud::Bigquery.new
  @dataset = @client.dataset "gasdb"

  # separate each type of fuel into different tables
  # denormalize using repeated values for prices
  def self.create_station_prices

    $fuel_type.each do |type|
      puts "creating table #{type}_station_prices"

      begin
        table = @dataset.create_table "#{type}_station_prices" do |schema|
          schema.integer "station_id", mode: :required
          schema.string "location", mode: :required
          schema.string "name", mode: :required
          schema.string "address", mode: :nullable
          schema.string "phone", mode: :nullable
          schema.float "latitude", mode: :required
          schema.float "longitude", mode: :required

          schema.record "prices", mode: :repeated do |prices_schema|
            prices_schema.timestamp "collected", mode: :required
            prices_schema.timestamp "reported", mode: :required
            prices_schema.float "price", mode: :required
            prices_schema.string "user", mode: :required
          end
        end
        table.description = "#{type} fuel prices at each station"
      rescue Exception => e
        puts "Error: #{e}"
      end
    end
  end

  def self.delete_station_prices
    $fuel_type.each do |type|
      begin
        puts "Deleting table #{type}_station_prices"
        table = @dataset.table "#{type}_station_prices"
        table.delete
      rescue Exception => e
        puts "Error: #{e}"
      end
    end
  end

end

