/*
  graph (ver. 0.1) -- Routines for the identification of minimum and
  maximum spanning tree.

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

#include "union_find.h"
#include "graph.h"
#include <stdio.h> 

/* comparison function used to order graph edges */


int compare_edge_greater(const void *e1, const void *e2){

  const Edge *edge1 = (const Edge *) e1;
  const Edge *edge2 = (const Edge *) e2;

  return (edge1->weight > edge2->weight) - (edge1->weight < edge2->weight);

}

int compare_edge_lesser(const void *e1, const void *e2){

  const Edge *edge1 = (const Edge *) e1;
  const Edge *edge2 = (const Edge *) e2;

  return (edge1->weight < edge2->weight) - (edge1->weight > edge2->weight);

}


/* 

   compute an ordered spanning tree of a weighted graph. If the graph
   is not connected, a minimum spanning forest is returned.

   Input:

   N        number of nodes in the graph
   
   edges    list of edges

   E        number of edges

   compare  function used to order edges (qsort syntax)


   Output:

   tree   list of edges in the spanning tree

   T      number of edges in the spanning tree

   Note: T is equal to V minus the number of connected blocks of the
   original graph.

*/


void 
ost(size_t V, Edge *edges, size_t E, 
    int (*compare) (const void *, const void *),Edge **tree, size_t *T){

  size_t i;

  size_t e=0;


  /* sort the list of edges */
  if(compare != NULL)
    qsort(edges,E,sizeof(Edge),compare);

  /* create the tree and allocate the maximum length */
  *tree = malloc( (V-1)*sizeof(Edge) );

  /* create the forest */
  forest_node ** forest = malloc( V*sizeof(forest_node *));

  for(i=0;i<V;i++)
    forest[i] = MakeSet(NULL); 	/* the value is not relevant */

  /* main loop */
  *T=0; /* number of edges in the tree */
  e=0;  /* position in edges list */
  while(e<E){
    size_t v1 = edges[e].orig-1;
    size_t v2 = edges[e].dest-1;

    if( Find(forest[v1]) != Find(forest[v2]) ){
      (*tree)[*T]=edges[e];
      Union(forest[v1],forest[v2]);
      *T +=1;
    }
    e++;
  }

  /* free the forest*/
  for(i=0;i<V;i++)
    free(forest[i]);
  free(forest);

  /* resize the tree */
  if(*T < V-1)
    *tree = realloc((void *) *tree, (*T)*sizeof(Edge) );

}



/* 

   mst compute a minimum spanning tree of a connected weighted
   graph. If the graph is not connected, a minimum spanning forest is
   returned.

   Input:

   V      number of nodes in the graph
   
   edges  list of edges

   E      number of edges


   Output:

   tree   list of edges in the spanning tree

   T      number of edges in the spanning tree

   Note: T is equal to V minus the number of connected blocks of the
   original graph.

*/


void 
mst(size_t V, Edge *edges, size_t E,  Edge **tree, size_t *T){

  ost(V, edges,E,compare_edge_greater,tree,T);

}

/* 

   Mst compute a maximum spanning tree of a connected weighted
   graph. If the graph is not connected, a maximum spanning forest is
   returned.

   Input:

   V      number of nodes in the graph
   
   edges  list of edges

   E      number of edges


   Output:

   tree   list of edges in the spanning tree

   T      number of edges in the spanning tree

   Note: T is equal to V minus the number of connected blocks of the
   original graph.

*/

void 
Mst(size_t V, Edge *edges, size_t E,  Edge **tree, size_t *T){

  ost(V, edges,E,compare_edge_lesser,tree,T);  

}

/* 

   This function takes an adjacency representation of a weighted
   graph: a square matrix W whose entry W[i][j] is the weight of the
   link i->j if it exists or zero otherwise and returns a list of
   edges. Notice that un-directed graph can be seen as symmetric
   matrix. The elements on the main diagonal are ignored.

   Input:

   A number of nodes

   W weight matrix W[a][b] with a,b in 1..A

   Output:

   E      number of edges
   edges list of edges

 */

void
adjacency2graph(size_t A, double **W,size_t *E, Edge **edges){

  size_t i,j,count;

  /* max number of edges */
  *E=(A*(A-1))/2;

  /* initial allocation of graph */
  *edges = (Edge *) malloc( (*E)*sizeof(Edge));

  count=0;
  for (i = 0; i < A; i++){
    for (j = 0; j < A; j++){
      if(j != i && W[i][j] != 0){
	(*edges)[count].orig = i+1;
	(*edges)[count].dest = j+1;
	(*edges)[count].weight = W[i][j];
	count ++;
      }
    }
  }

  /* save the number of edges */
  *E=count;

  /* set the proper dimension for graph  */
  *edges = (Edge *) realloc( (void *) *edges,(*E)*sizeof(Edge));

}


/* 

   This function takes a list of weighted edges and returns an
   adjacency representation: a square matrix W whose entry W[i][j] is
   the weight of the link i->j if it exists or zero otherwise.  Notice
   that un-directed graph contains both the link i->j and j->i with
   the same weight and generate a symmetric matrix. The elements on
   the main diagonal are set to zero.


   Input:

   E      number of edges
   edges  list of edges

   Output:

   A number of nodes
   W weight matrix W[a][b] with a,b in 1..A


 */

void
graph2adjacency(size_t E, Edge *edges,size_t *A, double ***W){

  size_t i;


  /* compute the maximum number of nodes */
  *A=0;
  for (i = 0; i < E; i++){
    if(edges[i].orig > *A) *A = edges[i].orig ;
    if(edges[i].dest > *A) *A = edges[i].dest ;
  }

  /* allocate the weight matrix */
  *W = (double **) malloc((*A)*sizeof(double*));
  for(i = 0; i < (*A); i++)
    (*W)[i] = (double *) calloc((*A),sizeof(double));

  /* build the weight matrix */
  for (i = 0; i < E; i++){
    (*W)[edges[i].orig][edges[i].dest]=edges[i].weight;
  }

}


