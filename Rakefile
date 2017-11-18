require './scrape.rb'
require './organize.rb'

desc 'run scraper'
task :scrape do
  Scraper.scrape()
end

desc 'update stats'
task :update_stats do
  Organizer.update_stats()
end

desc 'dropbox save'
task :dropbox_save do
  Organizer.dropbox_save()
end

desc 'cleanup old prices'
task :cleanup_old_prices do
  Organizer.cleanup_old_prices()
end