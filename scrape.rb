require 'delegate'
require 'HTTParty'
require 'nokogiri'
require 'dotenv/load'
require 'date'
require 'time'
require 'sequel'



DB = Sequel.connect(ENV['DATABASE_URL'])

def parseStation(name, location, station_id)

    url = "http://www.sanfrangasprices.com/#{name}_Gas_Stations/#{location}/#{station_id}/index.aspx"

    page = Nokogiri::HTML(HTTParty.get(url))

    info = page.xpath('//*[@id="spa_cont"]/div[1]/dl')

    data = Hash.new('')

    data[:name] = info.css('dt').text.strip

    address, phone = info.css('dd').text.split(/[Pp]hone:/)
    data[:address] = address.strip
    data[:phone] = phone.strip

    puts data

    begin
        DB[:stations].insert(:station_id => station_id,
                             :location => location,
                             :name => data[:name],
                             :address => data[:address],
                             :phone => data[:phone])
    rescue
        # nothing
    end

end



def parseLocation(location, fuel)

    fuel_type = {
        :regular => :A,
        :midgrade => :B,
        :premium => :C,
        :diesel => :D
    }

    type = fuel_type[fuel]

    url = "http://www.sanfrangasprices.com/GasPriceSearch.aspx?fuel=#{type}&typ=adv&srch=1&state=CA&area=#{location}&site=SanFran,SanJose,California&tme_limit=4"

    page = Nokogiri::HTML(HTTParty.get(url))
    rows = page.xpath('//*[@id="pp_table"]/table/tbody/tr')

    collected = Time.now

    rows.each { |row|
        data = Hash.new('')

        p_price = row.css('.p_price')
        data[:price] = Float(p_price.text)
        data[:station_id] = Integer(p_price[0]['id'].split('_').last)

        address = row.css('.address')
        data[:name] = address.css('a').text.strip
        data[:address] = address.css('dd').text.strip

        data[:user] = row.css('.mem').text.strip
        data[:reported] = DateTime.parse(row.css('.tm')[0]['title']).to_time

        puts data

        begin
            DB.transaction do
                while (DB[:stations].where(:station_id => data[:station_id]).count < 1)
                    parseStation(data[:name], location, data[:station_id])
                end

                DB[:prices].insert(:station_id => data[:station_id],
                                   :collected => collected,
                                   :reported => data[:reported],
                                   :type => 'regular',
                                   :price => data[:price],
                                   :user => data[:user])
            end

        rescue
            # nothing
        end
    }

end

parseLocation('Sunnyvale', :regular)