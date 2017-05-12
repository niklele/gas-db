# gas-db
build a DB of gasoline prices from the web

## Setup

1. Install postgresql however you would like
2. `bundle install`
3. `bundle exec rake setup_db` creates db tables

## Usage
`bundle exec rake scrape`

## Cleanup
`bundle exec rake teardown_db` deletes all tables and data
