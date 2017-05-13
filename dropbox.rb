require 'dotenv/load'
require 'dropbox-api'

class DropboxClient
    Dropbox::API::Config.app_key = ENV['DROPBOX_APP_KEY']
    Dropbox::API::Config.app_secret = ENV['DROPBOX_APP_SECRET']
    Dropbox::API::Config.mode = 'sandbox' # single-directory app

    @@client = Dropbox::API::Client.new(:token => ENV['DROPBOX_OAUTH_TOKEN'],
                                        :secret => ENV['DROPBOX_OAUTH_SECRET'])


    def self.csvList()
        return @@client.search('prices')
    end

    def self.uploadPrices()
        num = csvList().count
        f = File.open('prices.csv')
        file = @@client.chunked_upload("prices_#{num+1}.csv", f)
        puts "Dropbox uploaded file to #{file.direct_url[:url]}"
        f.close()
    end
end