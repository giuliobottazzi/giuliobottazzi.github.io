#!/bin/zsh

#Author       : Giulio Bottazzi
#Last Modified: Time-stamp: <2015-06-08 01:37:46 Giulio Bottazzi>

#check that required tools are installed
#---------------------------------------

command -v wget >/dev/null 2>&1 || { echo >&2 "wget seems to be missing.  Aborting."; exit 1; }
command -v dos2unix >/dev/null 2>&1 || { echo >&2 "dos2unix seems to be missing.  Aborting."; exit 1; }
command -v gnuplot >/dev/null 2>&1 || { echo >&2 "gnuplot seems to be missing.  Aborting."; exit 1; }

#oil price data -  West texas Intermediate
#-----------------------------------------

echo -n "oil price data -  West texas Intermediate"

if [[ ! -e MCOILWTICO.csv  || $(( `date +'%s'`-`stat -c "%X" MCOILWTICO.csv` )) -gt 2678400 ]]; then
    #download data
    echo " download"
    [[ -e MCOILWTICO.csv ]] && mv MCOILWTICO.csv MCOILWTICO_OLD.csv
    wget http://research.stlouisfed.org/fred2/series/MCOILWTICO/downloaddata/MCOILWTICO.csv
    dos2unix MCOILWTICO.csv
    #remove headings and separate fields
    gawk -F',' 'NR>1 {print $1,$2}' MCOILWTICO.csv | sed 's/-/ /g' | gawk '{print $1,$2,$4}' > wtiprice.txt
else
    echo " up to date"
fi

#oil price data -  European brent
#--------------------------------

echo -n "oil price data -  European brent"

if [[ ! -e MCOILBRENTEU.csv  || $(( `date +'%s'`-`stat -c "%X" MCOILBRENTEU.csv` )) -gt 2678400 ]]; then
    #download data
    echo " download"
    [[ -e MCOILBRENTEU.csv ]] && mv MCOILBRENTEU.csv MCOILBRENTEU_OLD.csv
    wget http://research.stlouisfed.org/fred2/series/MCOILBRENTEU/downloaddata/MCOILBRENTEU.csv
    dos2unix MCOILBRENTEU.csv
    #remove headings and separate fields
    gawk -F',' 'NR>1 {print $1,$2}' MCOILBRENTEU.csv | sed 's/-/ /g' | gawk '{print $1,$2,$4}' | gawk '$1>1987 {print $0}' > brentprice.txt
else
    echo " up to date"
fi

#oil price data -  OPEC basket
#-----------------------------

echo -n "oil price data -  OPEC basket"

if [[ ! -e basketDayArchives.xml  || $(( `date +'%s'`-`stat -c "%X" basketDayArchives.xml` )) -gt 2678400 ]]; then
    #download data
    echo " download"
    [[ -e basketDayArchives.xml ]] && mv basketDayArchives.xml basketDayArchives_old.xml
    wget http://www.opec.org/basket/basketDayArchives.xml
    #remove header and footer and obtain daily data, then compute monthly average
    head -n -1 basketDayArchives.xml | tail -n +3 | sed 's/.*data="\(.*\)".*val="\(.*\)".*/\1 \2/' | tr '-' ' ' | gawk 'NR==1 {oldyear=$1; oldmonth=$2; count=1; ave=$4} NR>1{if($2 == oldmonth){count=count+1; ave=ave+$4} else {print oldyear, oldmonth, ave/count; oldyear=$1; oldmonth=$2; count=1; ave=$4}  }' > opecprice.txt
else
    echo " up to date"
fi

# USA Consumer Price Index, value=100 for the average prices of the 36 months in 1982, 1983 and 1984
#---------------------------------------------------------------------------------------------------

echo -n "U.S.A. Consumer Price Index"

if [[ ! -e cu.data.1.AllItems  || $(( `date +'%s'`-`stat -c "%X" cu.data.1.AllItems` )) -gt 2678400 ]]; then
    #download data
    echo " download"
    [[ -e cu.data.1.AllItems ]] && mv cu.data.1.AllItems cu.data.1.AllItems_old
    wget http://download.bls.gov/pub/time.series/cu/cu.data.1.AllItems
    dos2unix cu.data.1.AllItems
    # select "CUUR0000SA0" and remove "M13", which is the year average
    grep "CUUR0000SA0" cu.data.1.AllItems | grep -v "M13" | gawk '{print $2,substr($3,2),$4}' > uscpi.txt
    #compute rescaled prices
    paste wtiprice.txt =(gawk '$1>=1986 {print $3}' uscpi.txt) | gawk '$4 !="" {print $1,$2,100.0*$3/$4}' > wtirescaled.txt
    paste brentprice.txt =(gawk '$1>=1988 {print $3}' uscpi.txt) | gawk '$4 !="" {print $1,$2,100.0*$3/$4}' > brentrescaled.txt
    paste opecprice.txt =(gawk '$1>=2003 {print $3}' uscpi.txt) | gawk '$4 !="" {print $1,$2,100.0*$3/$4}' > opecrescaled.txt
else
    echo " up to date"
fi

# USD/EUR exchange rate
#----------------------

echo -n "USD/EUR exchange rate"

if [[ ! -e EXUSEU.csv  || $(( `date +'%s'`-`stat -c "%X" EXUSEU.csv` )) -gt 2678400 ]]; then
    #download data
    [[ -e EXUSEU.csv ]] && mv EXUSEU.csv EXUSEU_OLD.csv
    wget http://research.stlouisfed.org/fred2/series/EXUSEU/downloaddata/EXUSEU.csv
    #set in a proper format
    gawk '/^[0-9]*-[0-9]*-[0-9]*/ {print $0}' EXUSEU.csv | sed -e 's/,/ /g' | sed -e 's/-/ /g' | gawk '{print $1,$2,$4}' > exuseu.txt
    #obtain series in Euro starting from January 2003
    paste =( gawk '$1>=2003 {print $1,$2,$3}' wtiprice.txt ) =(  gawk '$1>=2003 {print $3}' exuseu.txt ) | gawk '$3>0 && $4>0 {print $1,$2,$3/$4}' > wtipriceeur.txt
    paste =( gawk '$1>=2003 {print $1,$2,$3}' brentprice.txt ) =(  gawk '$1>=2003 {print $3}' exuseu.txt ) | gawk '$3>0 && $4>0 {print $1,$2,$3/$4}' > brentpriceeur.txt
    paste =( gawk '$1>=2003 {print $1,$2,$3}' opecprice.txt ) =(  gawk '$1>=2003 {print $3}' exuseu.txt ) | gawk '$3>0 && $4>0 {print $1,$2,$3/$4}' > opecpriceeur.txt
else
    echo " up to date"
fi


# Euro Area CPI index, base year=2005
#------------------------------------

echo -n "Euro Area Consumer Price Index"

if [[ ! -e prc_hicp_midx.tsv.gz || $(( `date +'%s'`-`stat -c "%X" prc_hicp_midx.tsv.gz` )) -gt 2678400 ]]; then
     #download data 
     #description from:
     #http://epp.eurostat.ec.europa.eu/portal/page/portal/hicp/data/main_tables
     #HICP (2005=100) - Monthly data (index) prc_hicp_midx dataset
     #18.05.2010 1996M01 2010M04 1089053
    [[ -e prc_hicp_midx.tsv.gz ]] && mv prc_hicp_midx.tsv.gz prc_hicp_midx_OLD.tsv.gz      
    wget 'http://ec.europa.eu/eurostat/estat-navtree-portlet-prod/BulkDownloadListing?sort=1&file=data%2Fprc_hicp_midx.tsv.gz' -O  prc_hicp_midx.tsv.gz
     #extract series of dates (first line) and the index normalized to 2005
     #(2005), consumer price all items (CP00) for the entire EU area (EU)
     #and transform in format 'yyyy mm index'
    cat =(zcat prc_hicp_midx.tsv.gz | head -n 1) =(zcat prc_hicp_midx.tsv.gz | grep 'I05,CP00,EU' ) | gawk -F'\t' 'NR==1 {for(i=1;i<=NF;i++) times[i]=$i} ; NR==2 {for(i=1;i<=NF;i++) cpis[i]=$i} ; END { for(i=length(times);i>1;i--) if(cpis[i] !~ /\:/) { sub(/M/," ",times[i]); gsub(/[ep]/," ",cpis[i]) ; print times[i],cpis[i]} } ' > eucpi.txt
    #compute rescaled prices
    paste wtipriceeur.txt =(  gawk '$1>=2003 {print $3}' eucpi.txt ) | gawk '$3>0 && $4>0 {print $1,$2,100*$3/$4}' > wtirescaledeur.txt
    paste brentpriceeur.txt =(  gawk '$1>=2003 {print $3}' eucpi.txt ) | gawk '$3>0 && $4>0 {print $1,$2,100*$3/$4}' > brentrescaledeur.txt
    paste opecpriceeur.txt =(  gawk '$1>=2003 {print $3}' eucpi.txt ) | gawk '$3>0 && $4>0 {print $1,$2,100*$3/$4}' > opecrescaledeur.txt
else
    echo " up to date"
fi


#OLD DOWNLOAD FROM THE EIA
#oil price data -  European brent
#--------------------------------
#

# echo -n "oil price data -  European brent"

# if [[ ! -e pet_pri_spt_s1_m.xls  || $(( `date +'%s'`-`stat -c "%X" pet_pri_spt_s1_m.xls` )) -gt 2678400 ]]; then
#     #download data
#     echo " download"
#     [[ -e pet_pri_spt_s1_m.xls ]] && mv pet_pri_spt_s1_m.xls pet_pri_spt_s1_m_OLD.xls
#     wget http://tonto.eia.doe.gov/dnav/pet/xls/pet_pri_spt_s1_m.xls
#     #convert to text file and set the proper date
#     xls2txt -n 1 pet_pri_spt_s1_m.xls 4: | gawk '$3>0 {print strftime("%Y %m",-2209078800+($1-1)*86400),$3}' | gawk '$1>1987 {print $0}' > brentprice.txt
#     #prepare rescaled prices
#     paste brentprice.txt =(gawk '$2>=1988 {print $4}' cpi-ur.txt) | gawk '$4 !="" {print $1,$2,100.0*$3/$4}' > brentrescaled.txt
# else
#     echo " up to date"
# fi

#oil price data -  Dubai crude
#--------------------------------

# echo -n "oil price data -  Dubai crude"

# if [[ ! -e WEPCDUBAFw.xls  || $(( `date +'%s'`-`stat -c "%X" WEPCDUBAFw.xls` )) -gt 2678400 ]]; then
#     #download data
#     echo " download"
#     [[ -e WEPCDUBAFw.xls ]] && mv WEPCDUBAFw.xls WEPCDUBAFw_OLD.xls
#     wget http://www.eia.doe.gov/dnav/pet/hist_xls/WEPCDUBAFw.xls

#     #extract data, put date in proper format, average elements inside the same month to obtain a monthly statistics
#     xls2txt -n 1 WEPCDUBAFw.xls 4: | gawk '{print strftime("%Y %m",-2209078800+($1-1)*86400),$2}' | gawk 'BEGIN {omonth="01";oyear=1997;num=0;price=0} $1>=1997 {if($2 != omonth) {print oyear,omonth,price/num; oyear=$1; omonth=$2;price=$3;num=1} else {price = price+$3;num=num+1 }  } END {print oyear,omonth,price/num}' > dubaiprice.txt

#     #prepare rescaled prices
#     paste dubaiprice.txt =(gawk '$2>=1997 {print $4}' cpi-ur.txt) | gawk '$4 !="" {print $1,$2,100.0*$3/$4}' > dubairescaled.txt
# else
#     echo " up to date"
# fi


# Produce necessary plots
#------------------------

echo "make plots"

gnuplot plots.gp

# Update report timestamp
#------------------------

sed -i'.old' -e "s/Date :: *\(.*\)/Date ::      `LANG='en_US' date +'%B %d %Y'`/" report.org

