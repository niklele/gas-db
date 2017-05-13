# gas-db
build a DB of gasoline prices from the web

## Setup

1. Install postgresql however you would like
2. `bundle install`
3. `rake dropbox:authorize` to authorize this single client
4. set environment variables in .env
    - `DATABASE_URL` postgres URL
    - `DROPBOX_OAUTH_TOKEN` from step 3
    - `DROPBOX_OAUTH_SECRET` from step 3
5. `rake setup` creates db tables

## Usage
1. `rake scrape` to scrape for info
2. `rake summary` for summary stats

## Cleanup
`rake teardown` deletes all tables and data

## License
MIT License