require 'open-uri'
require 'nokogiri'
require 'dotenv/load'
require 'date'
require 'time'
require 'uri'
require './bigquery'

$fuel_type = {
  'regular' => 'A',
  'midgrade' => 'B',
  'premium' => 'C',
  'diesel' => 'D'
}

$locations = ['Atherton',
              'Belmont',
              'Broadmoor',
              'Burbank',
              'Burlingame',
              'Campbell',
              'Colma',
              'Cupertino',
              'Daly City',
              'East Palo Alto',
              'Foster City',
              'Gilroy',
              'Half Moon Bay',
              'Hillsborough',
              'Lexington Hills',
              'Los Altos',
              'Los Gatos',
              'Menlo Park',
              'Millbrae',
              'Montara',
              'Monte Sereno',
              'Morgan Hill',
              'Moss Beach',
              'Mountain View',
              'Pacifica',
              'Palo Alto',
              'Portola Valley',
              'Redwood City',
              'San Bruno',
              'San Carlos',
              'San Mateo',
              'Santa Clara',
              'Saratoga',
              'South San Francisco',
              'Sunnyvale',
              'Woodside']

def parseStation(name, location, station_id)

  puts "scraping #{name} station in #{location} with id #{station_id}"

  location = location.gsub('Redwood City', 'Redwood_City')
  name = name.gsub(/ & /, '_-and-_')
  url = URI.escape("http://www.sanfrangasprices.com/#{name}_Gas_Stations/#{location}/#{station_id}/index.aspx")

  page = Nokogiri::HTML(open(url))

  info = page.xpath('//*[@id="spa_cont"]/div[1]/dl')

  station_data = Hash.new('')
  station_data[:station_id] = station_id
  station_data[:location] = location
  station_data[:url] = url

  station_data[:name] = info.css('dt').text.strip
  address, phone = info.css('dd').text.split(/phone:/i)
  station_data[:address] = address.strip

  if phone.nil?
    station_data[:phone] = ''
  else
    station_data[:phone] = phone.strip
  end

  mapLink = page.xpath('//*[@id="spa_cont"]/div[1]/div[1]/a')[0]['href']
  station_data[:latitude] = Float(mapLink.match(/lat=(-?\d+.\d+)/).captures[0])
  station_data[:longitude] = Float(mapLink.match(/long=(-?\d+.\d+)/).captures[0])

  puts station_data

  begin
    BigQuery.stations.insert station_data
  rescue => e
    puts "Error: #{e}"
  end

end

def parseLocation(location, fuel)

  puts "scraping prices in #{location} for #{fuel} fuel"

  type = $fuel_type[fuel]

  url = URI.escape("http://www.sanfrangasprices.com/GasPriceSearch.aspx?fuel=#{type}&typ=adv&srch=1&state=CA&area=#{location}&site=SanFran,SanJose,California&tme_limit=4")

  page = Nokogiri::HTML(open(url))
  rows = page.xpath('//*[@id="pp_table"]/table/tbody/tr')

  collected = Time.now

  rows.each do |row|

    if row.css('.address').css('a').first['href'].match(/redirect/i)
      puts "skipping station with a redirect"
      next
    end

    if row.css('.address').css('a').first['href'].match(/FUEL/)
      puts "skipping FUEL 24:7 station with a bad URL"
      next
    end

    price_data = Hash.new('')
    price_data[:collected] = collected
    price_data[:type] = fuel

    p_price = row.css('.p_price')
    price_data[:price] = Float(p_price.text)
    price_data[:station_id] = Integer(p_price[0]['id'].split('_').last)

    address = row.css('.address')
    station_name = address.css('a').text.strip
    # station_address = address.css('dd').text.strip

    price_data[:user] = row.css('.mem').text.strip
    price_data[:reported] = DateTime.parse(row.css('.tm')[0]['title']).to_time

    puts price_data

    # insert price record
    begin
      BigQuery.prices.insert price_data
    rescue => e
      puts "Error: #{e}"
    end

    # scrape station if it isn't in the table
    if not BigQuery.has_station? price_data[:station_id]
      sleep(0.5) # rate limiting
      parseStation(station_name, location, price_data[:station_id])
    end

  end

end

$locations.each do |loc|
  $fuel_type.keys.each do |fuel|
    parseLocation(loc, fuel)
    sleep(0.5) # rate limiting
  end
end