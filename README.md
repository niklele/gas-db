# gas-db
build a DB of gasoline prices from the web

## Setup
1. setup a Google Big Query project
2. make a file called `.env` and define the following environment variables:
    - `BIGQUERY_PROJECT` from google cloud platform console
    - `BIGQUERY_KEYFILE` path to JSON key for BigQuery Admin
3. bundle install
4. `rake setup` to create tables on BigQuery

## Usage
1. `rake scrape` to scrape for info
2. `rake summary` for summary stats

## Cleanup
`rake delete` deletes all tables and data from BigQuery

## Help
`rake -T` lists available rake tasks

## License
MIT License