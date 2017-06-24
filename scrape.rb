require 'open-uri'
require 'nokogiri'
require 'dotenv/load'
require 'date'
require 'time'
require 'sequel'
require 'uri'

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

DB = Sequel.connect(ENV['DATABASE_URL'])

def parseStation(name, location, station_id)

    puts "scraping #{name} station in #{location} with id #{station_id}"

    location = location.gsub('Redwood City', 'Redwood_City')
    name = name.gsub(/ & /, '_-and-_')
    url = URI.escape("http://www.sanfrangasprices.com/#{name}_Gas_Stations/#{location}/#{station_id}/index.aspx")

    page = Nokogiri::HTML(open(url))

    info = page.xpath('//*[@id="spa_cont"]/div[1]/dl')

    data = Hash.new('')

    data[:name] = info.css('dt').text.strip
    address, phone = info.css('dd').text.split(/phone:/i)
    data[:address] = address.strip

    if phone.nil?
        data[:phone] = ''
    else
        data[:phone] = phone.strip
    end

    mapLink = page.xpath('//*[@id="spa_cont"]/div[1]/div[1]/a')[0]['href']
    data[:lat] = Float(mapLink.match(/lat=(-?\d+.\d+)/).captures[0])
    data[:long] = Float(mapLink.match(/long=(-?\d+.\d+)/).captures[0])

    puts data

    begin
        DB[:stations].insert(:station_id => station_id,
                             :location => location,
                             :name => data[:name],
                             :address => data[:address],
                             :phone => data[:phone])

        # TODO put lat, long into db
    rescue => e
        puts e
        # nothing
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

        data = Hash.new('')

        p_price = row.css('.p_price')
        data[:price] = Float(p_price.text)
        data[:station_id] = Integer(p_price[0]['id'].split('_').last)

        address = row.css('.address')
        data[:name] = address.css('a').text.strip
        data[:address] = address.css('dd').text.strip

        address = row.css('.address')
        data[:name] = address.css('a').text.strip
        data[:address] = address.css('dd').text.strip

        data[:user] = row.css('.mem').text.strip
        data[:reported] = DateTime.parse(row.css('.tm')[0]['title']).to_time

        puts data

        noStation = false
        tries = 0
        begin
            DB.transaction do
                if (DB[:stations].where(:station_id => data[:station_id]).count < 1)
                    noStation = true
                    tries += 1

                    # rate limiting
                    sleep(0.5)

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
            if tries > 0
                next
            elsif noStation
                retry
            end

        end
    end

end

$locations.each do |loc|
    $fuel_type.keys.each do |fuel|

        parseLocation(loc, fuel)

        # rate limiting
        sleep(0.5)
    end
end