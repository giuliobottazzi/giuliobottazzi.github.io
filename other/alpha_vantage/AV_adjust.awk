# created: 29/10/2019

# Time-stamp: <2019-10-29 15:58:23 giulio>

BEGIN {
    print "#timestamp  open  high  low  close  volume  dividend  adjcoeff"
    tcoeff=1;
}

NR>1 {
    tcoeff=tcoeff*$9;
    gsub(/-/,"",$1);
    date[NR]=$1;
    open[NR]=$2;
    high[NR]=$3;
    low[NR]=$4;
    pclose[NR]=$5;
    volume[NR]=$7;
    dividend[NR]=$8;
    coeff[NR]=tcoeff
}

END {
    for(i=2;i<=NR;i++)
	print date[i],open[i],high[i],low[i],pclose[i],volume[i],dividend[i],coeff[i]/tcoeff
}
