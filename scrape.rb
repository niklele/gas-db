require 'open-uri'
require 'nokogiri'
require 'dotenv/load'
require 'date'
require 'time'
require 'uri'
require 'logger'
require 'colorize'
require 'neatjson'
require './mongo_client.rb'

class Scraper

  @logger = Logger.new(STDOUT)
  @logger.level = Logger::DEBUG
  @logger.progname = 'Scraper'
  # TODO make a custom formatter that calls super, then colorizes based on log level

  def self.parse_nearby(latitude, longitude)

    @logger.info { "parsing nearby lat: #{latitude} lng: #{longitude}".yellow }

    url = URI.escape("https://www.gasbuddy.com/Station/Nearby?lat=#{latitude}&lng=#{longitude}")
    stations = JSON.parse(open(url).read)

    # we can get a lot of fields from here, but we can't get all prices.
    # Instead we will just get the ids for parse_station

    # stations.each do |s|
    #   s = s['Station']
    #   station = {
    #     :_id => s['Id'],
    #     :name => s['Name'],
    #     :lat => s['Lat'],
    #     :lng => s['Lng'],
    #     :city => s['City'],
    #     :address => s['Address'],
    #     :zip => s['ZipCode'],
    #     :country => s['Country'],
    #     :state => s['State'],
    #     :phone => s['Phone'],
    #     :rating => s['Rating']
    #   }
    #   puts JSON.neat_generate(station).green
    # end

    return stations.map { |s| s['Station']['Id'] }
    # TODO figure out how to cleanly put these in the db
  end

  def self.parse_station(station_id)

    @logger.info { "parsing station #{station_id}".yellow }

    url = URI.escape("https://www.gasbuddy.com/Station/#{station_id}")
    page = Nokogiri::HTML(open(url))

    data = {}

    data[:name] = page.at_css('h2.station-name').text.strip # Valero
    data[:phone] = page.at_css('div.station-phone').text.strip

    # TODO can i use this address even though it has the cross street?
    # data[:address] = page.at_css('.station-address').text.strip
    # data[:area] = page.at_css('.station-area').text.strip

    data[:latitude] = page.at_css('meta[itemprop=latitude]')['content']
    data[:longitude] = page.at_css('meta[itemprop=longitude]')['content']

    data[:features] = page.css('div.station-feature').map do |e|
      {
        :name => e['title'],
        :image_url => URI.escape(/'(.*)\?/.match(e['style'])[1]) # get just url
      }
    end

    # TODO put station in mongo

    # MongoClient.open(true) do |mc|
    #   puts "test".green
    # end

    puts JSON.neat_generate(data).green

    ### price ###

    price_boxes = page.xpath('//*[@id="prices"]/div/div')

    # TODO mongo function to add multiple prices

    prices = price_boxes.each do |box|

      cash = self.parse_price_box(station_id, box, 'cash')
      puts JSON.neat_generate(cash).blue

      credit = self.parse_price_box(station_id, box, 'credit')
      puts JSON.neat_generate(credit).blue
    end

    # TODO put each price as an individual document in mongo

    # TODO remove nulls

    # puts JSON.neat_generate(prices).blue

  end

  def self.parse_price_box(station_id, type_box, payment_type)
    box = type_box.at_css("div.bottom-buffer-sm.#{payment_type}-box")
    price = box.at_css('div.price-display').text.to_f

    # check that we have a real price and not just '---'
    if price > 0
     
      return {
        :station_id => station_id,
        :fuel_type => type_box.at_css('h4.fuel-type.section-title').text.downcase,
        :payment_type => payment_type,
        :price => price,
        :reported => box.at_css('div.price-time').text,
        :user => box.at_css('span.memberId').text

        # TODO collected time
      }
      # TODO convert reported time to time object
    end
  end

  # TODO use a queue of station_ids to scrape

end

Scraper.parse_station 12361
Scraper.parse_station 5443
Scraper.parse_station 5024

# puts Scraper.parse_nearby(37.380875, -122.074536)

