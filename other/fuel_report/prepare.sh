#!/bin/zsh

#Author       : Giulio Bottazzi
#Last Modified: Time-stamp: <2021-01-15 15:04:22 giulio>

#compare the behaviour of oil price and its derivative on a weekly
#basis.

#check that required tools are installed
#---------------------------------------
command -v wget >/dev/null 2>&1 || { echo >&2 "wget seems to be missing.  Aborting."; exit 1; }
command -v xlsx2csv >/dev/null 2>&1 || { echo >&2 "xls2csv seems to be missing.  Aborting."; exit 1; }
command -v dos2unix >/dev/null 2>&1 || { echo >&2 "dos2unix seems to be missing.  Aborting."; exit 1; }
command -v gbinterp >/dev/null 2>&1 || { echo >&2 "gbinterp seems to be missing.  Aborting."; exit 1; }
command -v gnuplot >/dev/null 2>&1 || { echo >&2 "gnuplot seems to be missing.  Aborting."; exit 1; }

# Oil derivatives price data 
#---------------------------

#Data on oil derivatives can be obtained from the Market observatory
#of the European Commission on Oil. Data expressed as EUR/KL (thousand
#of liters).
#http://ec.europa.eu/energy/observatory/oil/bulletin_en.html save in a
#file with format: yyyy-mm-dd super_price diesel_price
echo -n "Derivatives price data"
if [[ ! -e Oil_Bulletin_Prices_History.xlsx  || $(( `date +'%s'`-`stat -c "%X" Oil_Bulletin_Prices_History.xlsx` )) -gt 604800 ]]; then

    #download data
    mv Oil_Bulletin_Prices_History.xlsx Oil_Bulletin_Prices_History.xlsx_old
    wet http://ec.europa.eu/energy/observatory/reports/Oil_Bulletin_Prices_History.xlsx

    # Prices, net of duties and taxes.

    #Italy. It is necessary to delete a lot of garbage and find out
    #the part pertaining to Italy, labeled with IT. The data organized
    #in these columns: date, exchange rate,Euro-super 95, Automotive
    #gas oil, Heating Gas Oil, ?,?, GPL automotive

    #date format: yyyy-mm-dd
    xlsx2csv Oil_Bulletin_Prices_History.xlsx| sed -n -e '/IT/,/LT/p' |  tr -d '"' |  tr ',' ' ' | grep '^[ 0-9][0-9]' | tr '/' ' ' | gawk '{print strftime("%Y-%m-%d",mktime("20"$3" "$2" "$1" 0 0 0")),$5/1000,$6/1000}' |  tac> super_diesel_IT_price.txt
        
    #Same thing as above. Now it is the EU average that must be
    #singled out.
    xlsx2csv -s 4 Oil_Bulletin_Prices_History.xlsx |  tr -d '"' |  tr ',' ' ' | grep '^[ ]*[0-9]*/' | tr '/' ' ' | gawk '{print strftime("%Y-%m-%d",mktime("20"$3" "$2" "$1" 0 0 0")),$5/1000,$6/1000}' | tac  > super_diesel_EU_price.txt

    #insure the two files have the same dates
    join super_diesel_IT_price.txt super_diesel_EU_price.txt > .temp
    gawk '{print $1, $2, $3}' .temp > super_diesel_IT_price.txt
    gawk '{print $1, $4, $5}' .temp > super_diesel_EU_price.txt
    rm .temp

else
    echo " up to date"
fi

# USD/EUR daily exchange rate
#----------------------------

## USD/EUR daily exchange rate from yahoo finance
## https://finance.yahoo.com/quote/EURUSD%3DX/history?p=EURUSD%3DX
echo -n "USD/EUR exchange rate"
if [[ ! -e EURUSDd.csv  || $(( `date +'%s'`-`stat -c "%X" EURUSDd.csv` )) -gt 604800 ]]; then
    #download data
    USERAGENT="Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0"
    wget --user-agent=${USERAGENT} 'https://query1.finance.yahoo.com/v7/finance/download/EURUSD=X?period1=1070236800&period2=1610668800&interval=1d&events=history&includeAdjustedClose=true' -O EURUSDd.csv

    #date format: yyyy-mm-dd    
    gawk -F',' 'NR>1{if($5!="null"){print $1,$5}}' EURUSDd.csv > eurusd.txt

else
    echo " up to date"
fi


# Oil weekly price data - Brent crude since 2005
#-----------------------------------------------

echo -n "Oil price data (European brent)"
if [[ ! -e DCOILBRENTEU.csv  || $(( `date +'%s'`-`stat -c "%X" DCOILBRENTEU.csv` )) -gt 604800 ]]; then
    #download data
    echo " download"
    [[ -e DCOILBRENTEU.csv ]] && mv DCOILBRENTEU.csv DCOILBRENTEU_OLD.csv
    wget http://research.stlouisfed.org/fred2/series/DCOILBRENTEU/downloaddata/DCOILBRENTEU.csv
    dos2unix DCOILBRENTEU.csv

    #remove headings, separate fields and put in YYYY-MM-DD price
    #format, from 2004 to have beginning of year
    gawk -F',' 'NR>1 {print $1,$2}' DCOILBRENTEU.csv | sed 's/-/ /g' | gawk '{if($4!="." && $1>=2004 ) {print $1"-"$2"-"$3,$4}}' > brentprice.txt
    
    #compute the oil price in Euro;    
    join eurusd.txt brentprice.txt | gawk '{print $1,$3/$2}' > brentprice_eur.txt

    #the oil price data are obtained interpolating the weekly prices
    #obtained from U.S. Energy Information Administration in the exact day
    #for which the price of the derivatives are computed

    #extract the epoch from the derivatives price file and interpolate the
    #oil price.
    # save in a file with format:
    #  yyyy-mm-dd oil_price
    GB_OUT_FLOAT_FORMAT="% .9e" gbinterp -I =( gawk '{gsub("-"," ",$1); print mktime($1" 00 00 00") }'  super_diesel_EU_price.txt) < =( gawk '{gsub("-"," ",$1); print mktime($1" 00 00 00"),$2 }' brentprice_eur.txt ) | gawk '{printf "%s %.2f\n",strftime("%Y-%m-%d",$1),$2}' > oil_price.txt

    #remove intermediary files
    rm -f brentprice.txt brentprice_eur.txt dexuseu_brentday.txt

else
    echo " up to date"
fi

# Produce necessary plots
#------------------------

echo "make plots"

gnuplot plots.gp

# Update report timestamp
#------------------------

sed -i'.old' -e "s/Date :: *\(.*\)/Date ::      `LANG='en_US' date +'%B %d %Y'`/" report.org
