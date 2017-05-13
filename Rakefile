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

desc 'run scraper'
task :scrape do
    ruby 'scrape.rb'
end
