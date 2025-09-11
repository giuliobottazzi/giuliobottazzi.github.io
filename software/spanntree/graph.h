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

#include <stdlib.h>

/* type Edge */

typedef struct edge_t {
  size_t orig;
  size_t dest;
  double weight;
} Edge ;

/* exposed functions */

void ost(size_t, Edge *, size_t, 
	 int (*) (const void *, const void *),Edge **, size_t *);
void mst(size_t, Edge *, size_t,  Edge **, size_t *);
void Mst(size_t, Edge *, size_t,  Edge **, size_t *);

void adjacency2graph(size_t, double **,size_t *, Edge **);
void graph2adjacency(size_t, Edge *,size_t *, double ***);

