require 'dotenv/load'
require 'logger'
require 'colorize'
require 'neatjson'
require 'time'
require './mongo_client'

class Organizer

  def self.update_stats
    # save average price etc to a a different collection

    MongoClient.open(false) do |mc|

      # mc.insert(:statistics, {_id: 'asdf'})

      mc.most_recent_prices.each do |a|
        puts JSON.neat_generate(a)
      end

      # mc.average_price_by_type.each do |a|
      #   # mc.update(:statistics, a[:_id], a)
      #   # mc.insert(:statistics, a)
      #   puts JSON.neat_generate(a)
      # end
    end

  end

  def self.dropbox_save
    # save prices collected today to dropbox
  end

  def self.cleanup_old_prices
    # delete prices reported more than 1 week ago
    threshold = Time.now - (60*60*24*7)
    MongoClient.open(false) do |mc|
      mc.delete_old_prices(threshold)
    end
  end

end
