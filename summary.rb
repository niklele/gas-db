require 'dotenv/load'
require 'sequel'
require 'pg'

DB = Sequel.connect(ENV['DATABASE_URL'])

puts "#{DB[:stations].count} stations"
puts "#{DB[:prices].count} prices"

oldest = DB['select * from prices order by reported asc limit 1'].first[:reported]
newest = DB['select * from prices order by reported desc limit 1'].first[:reported]

puts "oldest price reported at #{oldest}"
puts "newest price reported at #{newest}"