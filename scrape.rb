require 'delegate'
require 'HTTParty'
require 'nokogiri'
require 'dotenv/load'

sunnyvaleHtml = HTTParty.get('http://www.sanfrangasprices.com/GasPriceSearch.aspx?fuel=A&typ=adv&srch=1&state=CA&area=Sunnyvale&site=SanFran,SanJose,California&tme_limit=4')

sunyvale = Nokogiri::HTML(sunnyvaleHtml)
rows = sunyvale.xpath('//*[@id="pp_table"]/table/tbody/tr')

data = Hash.new('')

p_price = rows[0].css('.p_price')
data[:price] = Float(p_price.text)
data[:station_id] = Integer(p_price[0]['id'].split('_').last)

address = rows[0].css('.address')
data[:name] = address.css('a').text
data[:address] = address.css('dd').text.strip

data[:user] = rows[0].css('.mem').text
data[:reported] = rows[0].css('.tm')[0]['title']

puts data