require "dropbox-api"
require "dropbox-api/tasks"
Dropbox::API::Tasks.install

require './db.rb'

desc 'create db tables'
task :setup do
    GasDB::setup()
end

desc 'teardown db tables and delete csv files'
task :teardown do
    GasDB::teardown()
end

desc 'print db summary info'
task :summary do
    GasDB::summary()
end

desc 'copy prices data into a csv file'
task :copy do
    GasDB::copy()
end

desc 'move prices data into a csv file'
task :move do
    GasDB::move()
end

desc 'move prices data into a csv file which is uploaded to dropbox'
task :dropbox_move do
    GasDB::dropbox_move()
end

desc 'run scraper'
task :scrape do
    ruby 'scrape.rb'
end
