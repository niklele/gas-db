require 'dotenv/load'
require 'dropbox_api'

module Dropbox

  @client = DropboxApi::Client.new

  def self.prices_list
    @client.search("prices").matches.map { |result| result.resource.name }
  end

  def self.upload_prices
    num = self.prices_list.size
    f = IO.read("prices.csv")
    res = @client.upload("/prices_#{num+1}.csv", f)
    puts "Dropbox uploaded file to #{res.path_display}"
  end

end
