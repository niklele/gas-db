# gas-db
build a DB of gasoline prices from the web

## Setup

1. Install postgresql however you would like
2. `bundle install`
3. `bundle exec rake setup` creates db tables

## Usage
1. `bundle exec rake scrape` to scrape for info
2. `bundle exec rake summary` for summary stats

## Cleanup
`bundle exec rake teardown` deletes all tables and data

## License
MIT License