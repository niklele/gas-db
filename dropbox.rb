require 'dotenv/load'
require 'dropbox-api'

Dropbox::API::Config.app_key = ENV['DROPBOX_APP_KEY']
Dropbox::API::Config.app_secret = ENV['DROPBOX_APP_SECRET']
Dropbox::API::Config.mode = 'sandbox' # single-directory app

client = Dropbox::API::Client.new(:token => ENV['DROPBOX_OAUTH_TOKEN'],
                                  :secret => ENV['DROPBOX_OAUTH_SECRET'])


puts client.account