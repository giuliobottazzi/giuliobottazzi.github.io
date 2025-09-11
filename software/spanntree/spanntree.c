/*
  spanntree (ver. 0.1) -- Compute minimum and maximum spanning tree

  Copyright (C) 2010 Giulio Bottazzi

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  (version 2) as published by the Free Software Foundation;
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/


#include <stdlib.h>
#include <stdio.h> 

#include "union_find.h"
#include "graph.h"

/* 

   Read the graph from standard input. The format is
   
   v
   o1 d1 w1
   o2 d2 w2
   ...
   
   the first line contains the number of vertex. Then a list follows
   with an edge on each line. 'o', 'd' and 'w' are the origin, the
   destination and the weight of each edge respectively.
   
   Return the maximum spanning tree as a list of edges

*/

int main(){
    
  size_t i;

  /* initial graph */
  size_t N;     /* number of nodes */
  size_t E;     /* number of edges */
  Edge * graph=NULL; /* original graph */
  size_t orig,dest;
  double weight;

  /* spanning forest */
  Edge * tree=NULL;  /* spanning forest */
  size_t T;	/* edges in the spanning forest */
  double wt;    /* total weight of the spanning forest */

  /* load the graph */
  E=0;
  N=0;
  while(scanf("%zd %zd %lf",&orig,&dest,&weight) != EOF){
    E++;
    if(orig>N) N=orig;
    if(dest>N) N=dest;
    graph = (Edge *) realloc(graph,E*sizeof(Edge));
    graph[E-1].orig = orig;
    graph[E-1].dest = dest;
    graph[E-1].weight = weight;
  }
  
  /* compute the minimum spanning tree */
  mst(N,graph,E,&tree,&T);

  /* output the result */
  printf("#minimum spanning tree\n");
  wt=0;
  for(i=0;i<T;i++){
    printf("%zd %zd %f\n",tree[i].orig,tree[i].dest,tree[i].weight);
    wt += tree[i].weight;
  }
  printf("#total weight = %f\n",wt);
  
  /* compute the maximum spanning tree */
  Mst(N,graph,E,&tree,&T);

  /* output the result */
  printf("#maximum spanning tree\n");
  wt=0;
  for(i=0;i<T;i++){
    printf("%zd %zd %f\n",tree[i].orig,tree[i].dest,tree[i].weight);
    wt += tree[i].weight;
  }
  printf("#total wight = %f\n",wt);
  

  return 0;

}
