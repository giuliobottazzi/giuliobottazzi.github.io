# Giulio Bottazzi, created May 21 2013

# Last modified:
# Time-stamp: <2015-04-26 23:13:16 Giulio Bottazzi>

# Alt-x run-octave : to start octave
# Ctrl-x o         : move to the other frame
# Ctrl-c Ctrl-i l  : to send a line
# Ctrl-c Ctrl-i b  : to send a block
# Ctrl-c Ctrl-i f  : to send a function
# Ctrl-c Ctrl-i r  : to send a region (selected part)

# From options prices to state prices
# ===================================


# Assume the payoff of a security can take a finite set of values
# [x1,...xN]. Then the market composed of the security and all put (or
# call) options at strike prices [x1,...xN] is a complete market. We
# can see it using data on derivatives on equity.

# The payoff of the equity at date 1 is just its price (we ignore
# dividend payment). Assume that the only prices the security can take
# are  the strike prices of the traded options. (see the picture at
# http://cafim.sssup.it/~giulio/teaching/options.png)

S=[20,20.5,21,21.5,22,22.5,23];


#Call options
#------------

#define the payoff matrix
Xcall=[S ; max(0,repmat(S,size(S,2),1)-repmat(S',1,size(S,2)))(1:end-1,:) ]

#build the array of prices using the "last traded" price
Pcall=[ 21.53  ; 1.54 ; 1.06 ; 0.55 ; 0.17 ; 0.04 ; 0.01 ]

#find the state prices
qcall=inv(Xcall)*Pcall

#Put options
#-----------

#define the payoff matrix
Xput=[max(0,-repmat(S,size(S,2),1)+repmat(S',1,size(S,2)))(2:end,:);S]

#build the array of prices using the "last traded" price
Pput=[0.01 ; 0.04; 0.17 ; 0.41; 1.20 ; 1.58; 21.53]

#find the state prices
qput=inv(Xput)*Pput


# Then we confine the analysis only to the most liquid assets, that is
# the options with the largest traded volumes.

Sliq=[21,21.5,22];

#Call options
#------------

#define the payoff matrix
Xliqcall=[Sliq ; max(0,repmat(Sliq,size(Sliq,2),1)-repmat(Sliq',1,size(Sliq,2)))(1:end-1,:) ]

#build the array of prices using the "last traded" price
Pliqcall=[ 21.53  ; 0.55 ; 0.17]

#find the state prices
qliqcall=inv(Xliqcall)*Pliqcall

#Put options
#-----------

#define the payoff matrix
Xliqput=[max(0,-repmat(Sliq,size(Sliq,2),1)+repmat(Sliq',1,size(Sliq,2)))(2:end,:);Sliq]

#build the array of prices using the "last traded" price
Pliqput=[ 0.17 ; 0.41; 21.53]

#find the state prices
qliqput=inv(Xliqput)*Pliqput
