require 'delegate'
require 'HTTParty'
require 'nokogiri'
require 'dotenv/load'
require 'date'
require 'time'
require 'sequel'

DB = Sequel.connect(ENV['DATABASE_URL'])

# TODO build stations so that foreign key constraint is met

sunnyvaleHtml = HTTParty.get('http://www.sanfrangasprices.com/GasPriceSearch.aspx?fuel=A&typ=adv&srch=1&state=CA&area=Sunnyvale&site=SanFran,SanJose,California&tme_limit=4')

sunyvale = Nokogiri::HTML(sunnyvaleHtml)
rows = sunyvale.xpath('//*[@id="pp_table"]/table/tbody/tr')

collected = Time.now

rows.each { |row|
    data = Hash.new('')

    p_price = row.css('.p_price')
    data[:price] = Float(p_price.text)
    data[:station_id] = Integer(p_price[0]['id'].split('_').last)

    address = row.css('.address')
    data[:name] = address.css('a').text
    data[:address] = address.css('dd').text.strip

    data[:user] = row.css('.mem').text
    data[:reported] = DateTime.parse(row.css('.tm')[0]['title']).to_time

    DB[:prices].insert(:station_id => data[:station_id],
                       :collected => collected,
                       :reported => data[:reported],
                       :type => 'regular',
                       :price => data[:price],
                       :user => data[:user])
}