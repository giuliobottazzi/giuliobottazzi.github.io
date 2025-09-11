#!/bin/bash

# created: GB June 2019

# Time-stamp: <2019-10-29 09:16:48 giulio>

#add your apikey
APIKEY=

#obtain the list of companies
wget --output-document=companies.txt 'http://www.nasdaq.com/screening/companies-by-name.aspx?letter=0&exchange=nyse&render=download'

#filter pharma firms
tickers=$( gawk -F, '{ if($7=="\"Major Pharmaceuticals\""){ gsub(/"/,"",$1); print $1} }' companies.txt )

#download data and save in file
AVWEB="https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&outputsize=full&apikey=${APIKEY}&datatype=csv"
for ticker in $tickers; do
    wget --output-document=${ticker}.csv "${AVWEB}&symbol=${ticker}"
    sleep 15s
done
