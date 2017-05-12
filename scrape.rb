require 'delegate'
require 'HTTParty'
require 'nokogiri'
require 'dotenv/load'
require 'date'
require 'time'
require 'sequel'
require 'uri'

# stations that can't be parsed properly bc of a problem on the website
$blacklist_stations = [4068]

$fuel_type = {
    'regular' => 'A',
    'midgrade' => 'B',
    'premium' => 'C',
    'diesel' => 'D'
}

$locations = ['Atherton',
              'Cupertino',
              'East Palo Alto',
              'Los Altos',
              'Menlo Park',
              'Mountain View',
              'Palo Alto',
              'Santa Clara',
              'Saratoga',
              'Sunnyvale']

DB = Sequel.connect(ENV['DATABASE_URL'])

def parseStation(name, location, station_id)

    puts "scraping #{name} station in #{location} with id #{station_id}"

    url = URI.escape("http://www.sanfrangasprices.com/#{name}_Gas_Stations/#{location}/#{station_id}/index.aspx")

    page = Nokogiri::HTML(HTTParty.get(url))

    info = page.xpath('//*[@id="spa_cont"]/div[1]/dl')

    data = Hash.new('')

    data[:name] = info.css('dt').text.strip

    address, phone = info.css('dd').text.split(/[Pp]hone:/)
    data[:address] = address.strip

    if phone.nil?
        data[:phone] = ''
    else
        data[:phone] = phone.strip
    end

    puts data

    begin
        DB[:stations].insert(:station_id => station_id,
                             :location => location,
                             :name => data[:name],
                             :address => data[:address],
                             :phone => data[:phone])
    rescue => e
        puts e
        # nothing
    end

end

def parseLocation(location, fuel)

    puts "scraping prices in #{location} for #{fuel} fuel"

    type = $fuel_type[fuel]

    url = URI.escape("http://www.sanfrangasprices.com/GasPriceSearch.aspx?fuel=#{type}&typ=adv&srch=1&state=CA&area=#{location}&site=SanFran,SanJose,California&tme_limit=4")

    page = Nokogiri::HTML(HTTParty.get(url))
    rows = page.xpath('//*[@id="pp_table"]/table/tbody/tr')

    collected = Time.now

    rows.each { |row|
        data = Hash.new('')

        p_price = row.css('.p_price')
        data[:price] = Float(p_price.text)
        data[:station_id] = Integer(p_price[0]['id'].split('_').last)

        if $blacklist_stations.include? data[:station_id]
            puts "skipping blacklisted station #{data[:station_id]}"
            next
        end

        address = row.css('.address')
        data[:name] = address.css('a').text.strip
        data[:address] = address.css('dd').text.strip

        data[:user] = row.css('.mem').text.strip
        data[:reported] = DateTime.parse(row.css('.tm')[0]['title']).to_time

        puts data

        noStation = false
        begin
            DB.transaction do
                if (DB[:stations].where(:station_id => data[:station_id]).count < 1)
                    noStation = true
                    parseStation(data[:name], location, data[:station_id])
                end

                DB[:prices].insert(:station_id => data[:station_id],
                                   :collected => collected,
                                   :reported => data[:reported],
                                   :type => fuel, # real name not A/B/C/D
                                   :price => data[:price],
                                   :user => data[:user])
            end

        rescue => e
            puts e
            if noStation
                retry
            end

        end
    }

end

$locations.each { |loc|
    $fuel_type.keys.each { |fuel|

        parseLocation(loc, fuel)

        # rate limiting
        sleep(1)
    }
}