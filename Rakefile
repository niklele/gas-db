require './db.rb'

desc 'create db tables'
task :setup do
    GasDB::setup()
end

desc 'teardown db tables'
task :teardown do
    GasDB::teardown()
end

desc 'print db summary info'
task :summary do
    GasDB::summary()
end

desc 'copy prices data into a new table'
task :copy do
    GasDB::copy()
end

desc 'move prices data into a new table'
task :move do
    GasDB::move()
end

desc 'run scraper'
task :scrape do
    ruby 'scrape.rb'
end
