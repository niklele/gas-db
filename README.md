# gas-db
build a DB of gasoline prices from the web

## Setup
1. Setup mongodb however you would like (I used mlab)
2. set environment variables in .env: 
    - `LOCAL_MONGODB_URI`
    - `MLAB_MONGODB_URI`
3. `bundle install`
4. use `bootstrap.rb` to init stations

## Usage
1. `rake scrape` to scrape for info

## License
MIT License