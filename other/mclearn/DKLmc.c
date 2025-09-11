/*
  DKLmc  (ver. 0.2) -- Monte-Carlo computation of average Kullback–Leibler divergence
  Copyright (C) 2025 Giulio Bottazzi

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  (version 2) as published by the Free Software Foundation;
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

/* compile with: gcc DKLmc.c -lm -lgsl -lgslcblas -o DKLmc -Wall -Wextra -pedantic -march=native -O3 -fopenmp  */
/* compile with -g and check with: valgrind --leak-check=full --show-leak-kinds=all ./DKLmc   */

#include <stdio.h>
#include <math.h>
#include <string.h>
#include <omp.h>
#include <gsl/gsl_rng.h>
#include <getopt.h>

/* parameter of the simulation */

struct MC {               // Monte Carlo parameters:
  unsigned long int Tmax; // maximum number of iterations
  unsigned int dT;        // iteration steps
  unsigned int n;         // number of initial weights
  double eps;             // relative error in DKL computation
  double abs;             // absolute error in DKL computation
  unsigned long int seed; // RNG seed
};


void evol(gsl_rng * r, double *weight, double *DKL, unsigned int *state, const double mu, const double lambda, const double pi1, const double pi2, const double pi, const unsigned int deltaT){

  /* initialize variables */
  double w = *weight;
  unsigned int s = *state;

  double D=0; 			/* DKL running average */
  double C=0;			/* DKL correction */
  for(unsigned int t=0;t<deltaT;t++){

    /* compute the probability */
    const double p = pi2 + w*(pi1-pi2);

    /* compute instantaneous DKL */
    const double d = pi*pi*log(pi/p)+(1-pi)*(1-pi)*log((1-pi)/p)+pi*(1-pi)*log(pi*(1-pi)/((1-p)*(1-p)));

    /* update sum of DKL with stability correction */
    const double delta = d-C; 
    const double Dtilde = D+delta; 
    C = Dtilde-D-delta;
    D = Dtilde;
    if(C> 1e-10) fprintf(stderr,"WARNING: high DKL correction: %e\n",C);

    /* generate the new state */
    const unsigned int snew = (gsl_rng_uniform(r) < pi ? 0 : 1);
    
    /* update the weight with stability correction */
    const double w1 = mu*lambda + (1-mu)*(snew == s ? pi1/p : (1-pi1)/(1-p))*w;
    const double w2 = mu*(1-lambda) + (1-mu)*(snew == s ? pi2/p : (1-pi2)/(1-p))*(1-w);
    w=w1/(w1+w2);
    
    /* update the present state */
    s=snew;
  }

  *weight = w;
  *DKL = D/deltaT;
  *state = s;
}

long unsigned int DKLaverage(gsl_rng ** R, double *DKLavg,double *DKLstd,const double mu, const double lambda, const double pi1, const double pi2, const double pi, const struct MC mc, char o_verbose){

  /* initial weights */
  double *w = (double *) calloc(mc.n,sizeof(double));
  for (unsigned int i=0;i<mc.n;i++){
    w[i]=(i+1)/(1.+mc.n);
  }

  double *DKL = (double *) calloc(mc.n,sizeof(double));
  double *dDKL = (double *) calloc(mc.n,sizeof(double));
  unsigned int *state = (unsigned int *) calloc(mc.n,sizeof(unsigned int));

  /* main loop */
  long unsigned int T=0;
  do{
    
    /* evolve the trajectories */
    #pragma omp parallel for
    for (unsigned int i=0;i<mc.n;i++){ 
      evol(R[i],w+i,dDKL+i,state+i,mu,lambda,pi1,pi2,pi,mc.dT); 
    } 
    
    /* update the average DKL */
    for (unsigned int i=0;i<mc.n;i++){
      DKL[i] += (dDKL[i]-DKL[i])*mc.dT/(T+mc.dT);
    }

    /* compute the average value and the error */
    double sum1=DKL[0], sum2=DKL[0]*DKL[0], DKLmin = DKL[0], DKLmax=DKL[0];
    for (unsigned int i=1;i<mc.n;i++){
      sum1 += DKL[i];
      sum2 += DKL[i]*DKL[i];
      if(DKL[1]< DKLmin) DKLmin = DKL[i];
      if(DKL[1]> DKLmax) DKLmax = DKL[i];
    }
    *DKLavg = sum1/mc.n;
    *DKLstd = sqrt((sum2-sum1*sum1/mc.n)/(mc.n-1));
            
    T+=mc.dT;
    /* dT*=2; */
    
    /* print the outcome */
    if(o_verbose>2)
      printf("> %lu %e %e %e\n",T,*DKLavg,*DKLstd,DKLmax-DKLmin);
    
  }
  while(T < mc.Tmax && (*DKLstd>mc.eps*(*DKLavg) || *DKLstd > mc.abs) );

  /* free allocated space */
  free(w);
  free(DKL);
  free(dDKL);
  free(state);

  return T;
}


int main(int argc,char* argv[]){

  /* parameter of the model */
  double pi1=0.25;
  double pi2=0.75;
  double pi=0.5;

  /* parameter of the agent */
  double mu=0.5;
  double minmu=0;
  double maxmu=1;
  double lambda=0.5;
  double minlambda=0;
  double maxlambda=1;
  
  struct MC mc;
  mc.Tmax = 1e6;
  mc.dT   = 1e2;
  mc.n    = 8;
  mc.eps  = 1e-2;
  mc.abs  = 1e-3;
  mc.seed = 100;
  unsigned int gridmu=10; //number of grid points when exploring parameter region
  unsigned int gridlambda=10; //number of grid points when exploring parameter region

  /* COMMAND LINE PROCESSING -------------------------- */ 
  char o_verbose = 0;   // set the verbosity level
  char o_murange=0;     // explore range of mu
  char o_lambdarange=0; // explore range of lambda
  
  struct option long_options[] = {
    {"version", no_argument,       NULL,  0 },
    {"help", no_argument,       NULL,  'h' },
    {"mu", required_argument,       NULL,  'm' },
    {"lambda", required_argument,       NULL,  'l' },
    {0,         0,                 0,  0 }
  };
  
  int option_index = 0;
  int opt;
  while((opt=getopt_long(argc,argv,"m:l:1:2:t:a:e:T:d:n:g:r:V:h",long_options,&option_index))!=EOF){
    if(opt==0){
      fprintf(stdout,"DKLmc 0.2\n\n");
      fprintf(stdout,"Copyright (C) 2025 Giulio Bottazzi\n");
      fprintf(stdout,"This program is free software; you can redistribute it and/or\n");
      fprintf(stdout,"modify it under the terms of the GNU General Public License\n");
      fprintf(stdout,"(version 2) as published by the Free Software Foundation;\n\n");
      fprintf(stdout,"This program is distributed in the hope that it will be useful,\n");
      fprintf(stdout,"but WITHOUT ANY WARRANTY; without even the implied warranty of\n");
      fprintf(stdout,"MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n");
      fprintf(stdout,"GNU General Public License for more details.\n\n");
      fprintf(stdout,"Written by Giulio Bottazzi\n\n");
      fprintf(stdout,"Report bugs to <giulio.bottazzi@gmail.com>\n\n");
      fprintf(stdout,"More on the program: <http://cafim.sssup.it/~giulio/other/mclearn/mclearn.html>\n");
      exit(0);
    }
    else if(opt=='m'){
      switch(sscanf(optarg,"%lf , %lf",&minmu,&maxmu)){
      case 0:
	fprintf(stderr,"Error conversion for option -l\n"); 
	exit(EXIT_FAILURE);
	break;
      case 1:
	mu = minmu;
	if(mu<0 || mu > 1){fprintf(stderr,"Value of mu out of bounds\n"); exit(EXIT_FAILURE);}
	break;
      default:
	if(minmu<0 || minmu > 1){fprintf(stderr,"Value of minmu out of bounds\n"); exit(EXIT_FAILURE);}
	if(maxmu<0 || maxmu > 1){fprintf(stderr,"Value of maxmu out of bounds\n"); exit(EXIT_FAILURE);}
	if(maxmu < minmu){const double dtmp1=minmu; minmu=maxmu; maxmu=dtmp1;}
	o_murange=1;
      }
    }
    else if(opt=='l'){
      switch(sscanf(optarg,"%lf , %lf",&minlambda,&maxlambda)){
      case 0:
	fprintf(stderr,"Error conversion for option -l\n"); 
	exit(EXIT_FAILURE);
	break;
      case 1:
	lambda = minlambda;
	if(lambda<0 || lambda > 1){fprintf(stderr,"Value of lambda out of bounds\n"); exit(EXIT_FAILURE);}
	break;
      default:
	if(minlambda <0 || minlambda > 1){fprintf(stderr,"Value of minlambda out of bounds\n"); exit(EXIT_FAILURE);}
	if(maxlambda <0 || maxlambda > 1){fprintf(stderr,"Value of maxlambda out of bounds\n"); exit(EXIT_FAILURE);}
	if(maxlambda < minlambda){const double dtmp1=minlambda; minlambda=maxlambda; maxlambda=dtmp1;}
	o_lambdarange=1;
      }
    }
    else if(opt=='1'){
      if(sscanf(optarg," %lf ",&pi1) == 0){fprintf(stderr,"Error conversion for option -1\n");exit(EXIT_FAILURE);}
      if(pi1 <0 || pi1 > 1){fprintf(stderr,"Value of pi_1 out of bounds\n"); exit(EXIT_FAILURE);}
    }
    else if(opt=='2'){
      if(sscanf(optarg," %lf ",&pi2) == 0){fprintf(stderr,"Error conversion for option -2\n"); exit(EXIT_FAILURE);}
      if(pi2 <0 || pi2 > 1){fprintf(stderr,"Value of pi_2 out of bounds\n"); exit(EXIT_FAILURE);}
    }
    else if(opt=='t'){
      if(sscanf(optarg," %lf ",&pi) == 0){fprintf(stderr,"Error conversion for option -t\n");exit(EXIT_FAILURE);}
      if(pi <0 || pi > 1){fprintf(stderr,"Value of pi out of bounds\n"); exit(EXIT_FAILURE);}
    }
    else if(opt=='a'){
      if(sscanf(optarg," %lf ",&mc.abs) == 0){fprintf(stderr,"Error conversion for option -a\n");exit(EXIT_FAILURE);}
      if(mc.abs <0){fprintf(stderr,"Value of abs out of bounds\n"); exit(EXIT_FAILURE);}
    }
    else if(opt=='e'){
      if(sscanf(optarg," %lf ",&mc.eps) == 0){fprintf(stderr,"Error conversion for option -e\n");exit(EXIT_FAILURE);}
      if(mc.eps <0){fprintf(stderr,"Value of eps out of bounds\n"); exit(EXIT_FAILURE);}
    }
    else if(opt=='T'){
      if(sscanf(optarg," %lu ",&mc.Tmax) == 0){fprintf(stderr,"Error conversion for option -T\n");exit(EXIT_FAILURE);}
    }
    else if(opt=='d'){
      if(sscanf(optarg," %u ",&mc.dT) == 0){fprintf(stderr,"Error conversion for option -d\n");exit(EXIT_FAILURE);}
    }
    else if(opt=='n'){
      if(sscanf(optarg," %u ",&mc.n) == 0){fprintf(stderr,"Error conversion for option -n\n");exit(EXIT_FAILURE);}
    }
    else if(opt=='r'){
      if(sscanf(optarg," %lu ",&mc.seed) == 0){fprintf(stderr,"Error conversion for option -r\n");exit(EXIT_FAILURE);}
    }
    else if(opt=='g'){
      switch(sscanf(optarg,"%u , %u",&gridmu,&gridlambda)){
      case 0:
	fprintf(stderr,"Error conversion for option -g\n"); 
	exit(EXIT_FAILURE);
	break;
      case 1:
	gridlambda = gridmu;
	break;
      }
    }
    else if(opt=='?'){
      fprintf(stderr,"option %c not recognized\n",optopt);
      exit(-1);
    }
    else if(opt=='V'){
      o_verbose = atoi(optarg);
    }
    else if(opt=='h'){
      /*print help*/
      fprintf(stdout,"Monte Carlo computation of the average Kullback–Leibler divergence (DKL)   \n");
      fprintf(stdout,"of a behavioral learning algorithm. If a comma separated range is provided \n");
      fprintf(stdout,"for mu or lambda, a tabular output is produced with equally spaced         \n");
      fprintf(stdout,"values in that range.                                                      \n");
      fprintf(stdout,"Usage: %s [options]                                                        \n\n",argv[0]);
      fprintf(stdout,"Options:                                                                   \n");
      fprintf(stdout," -m  set mu (default 0.5)                                                  \n");
      fprintf(stdout," -l  set lambda (default 0.5)                                              \n");
      fprintf(stdout," -1  set pi1 (default 0.25)                                                \n");
      fprintf(stdout," -2  set pi2 (default 0.75)                                                \n");
      fprintf(stdout," -t  set pi (default 0.5)                                                  \n");
      fprintf(stdout," -a  set the maximum absolute error (default 1e-3)                         \n");
      fprintf(stdout," -e  set the maximum relative error (default 1e-2)                         \n");
      fprintf(stdout," -T  set the maximum number of steps of the simulation (default 1e6)       \n");
      fprintf(stdout," -d  set the steps increment (default 100)                                 \n");
      fprintf(stdout," -n  set the number of initial weights (default 8)                         \n");
      fprintf(stdout," -g  set the number of grid points for tabular output (default 10)         \n");
      fprintf(stdout,"     with two comma separated values, set the grid point for mu and lambda \n");
      fprintf(stdout," -V  verbosity level (default 0)                                           \n");
      fprintf(stdout,"      0  only warnings                                                     \n");
      fprintf(stdout,"      1  print the values of model parameters                              \n");
      fprintf(stdout,"      2  print the values of Monte Carlo parameters                        \n");
      fprintf(stdout,"      3  print intermediate DKL estimate and error at each step            \n");
      fprintf(stdout," -h  print this message         \n");
      exit(0);
    }
  }
  /* END OF COMMAND LINE PROCESSING ------------------- */ 

  /* allocate and initialize RNG */
  gsl_rng ** R = (gsl_rng **) calloc(mc.n,sizeof(gsl_rng *));
  for (unsigned int i=0;i<mc.n;i++){
    R[i]=gsl_rng_alloc (gsl_rng_taus2);
    gsl_rng_set(R[i],mc.seed+i);
  }

  double DKLavg=0, DKLstd=0; // DKL average and standard error
  long unsigned int T=0;          // simulation length

  /* select the type of output based on the value provided by options -m and -l */
  if(o_murange == 0 && o_lambdarange==0){// single value
    if(o_verbose>0)
      printf("# mu=%e lambda=%e pi1=%e pi2=%e pi=%e\n",mu,lambda,pi1,pi2,pi);
    T=DKLaverage(R,&DKLavg,&DKLstd,mu,lambda,pi1,pi2,pi,mc,o_verbose);
    if(o_verbose>1)
      printf("# abs=%e eps=%e T=%lu n=%u seed=%lu\n",mc.abs,mc.eps,T,mc.n,mc.seed);
    printf("# DKL avg    DKL st.dev.\n");
    printf("%e %e\n",DKLavg,DKLstd);
  }
  else if (o_murange == 1 && o_lambdarange==0) {// column output in mu
    if(o_verbose>0)
      printf("# lambda=%e pi1=%e pi2=%e pi=%e\n",lambda,pi1,pi2,pi);
    if(o_verbose>1)
      printf("# abs=%e eps=%e n=%u seed=%lu\n",mc.abs,mc.eps,mc.n,mc.seed);

    /* header --- */
    printf("# mu         DKL avg");
    if(o_verbose>0)
      printf("      DKL st.dev.");
    if(o_verbose>1)
      printf("  T.");
    printf("\n");	
    /* ---------- */
    for (unsigned int i=0;i<gridmu;i++){
      mu = minmu+(maxmu-minmu)*i/(gridmu-1);
      T=DKLaverage(R,&DKLavg,&DKLstd,mu,lambda,pi1,pi2,pi,mc,o_verbose);
      printf("%e %e ",mu,DKLavg);
      if(o_verbose>0)
	printf("%e ",DKLstd);
      if(o_verbose>1)
	printf("%lu ",T);
      printf("\n");
    }
  }
  else if (o_murange == 0 && o_lambdarange==1) {// column output in lambda
    if(o_verbose>0)
      printf("# mu=%e pi1=%e pi2=%e pi=%e\n",mu,pi1,pi2,pi);
    if(o_verbose>1)
      printf("# abs=%e eps=%e n=%u seed=%lu\n",mc.abs,mc.eps,mc.n,mc.seed);

    /* header --- */
    printf("# lambda     DKL avg");
    if(o_verbose>0)
      printf("      DKL st.dev.");
    if(o_verbose>1)
      printf("  T.");
    printf("\n");	
    /* ---------- */
    for (unsigned int i=0;i<gridlambda;i++){
      lambda = minlambda+(maxlambda-minlambda)*i/(gridlambda -1);
      T=DKLaverage(R,&DKLavg,&DKLstd,mu,lambda,pi1,pi2,pi,mc,o_verbose);
      printf("%e %e ",lambda,DKLavg);
      if(o_verbose>0)
	printf("%e ",DKLstd);
      if(o_verbose>1)
	printf("%lu ",T);
      printf("\n");
    }
  }
  else if (o_murange == 1 && o_lambdarange==1) {// tabular output
    if(o_verbose>0)
      printf("# pi1=%e pi2=%e pi=%e\n",pi1,pi2,pi);
    if(o_verbose>1)
      printf("# abs=%e eps=%e n=%u seed=%lu\n",mc.abs,mc.eps,mc.n,mc.seed);

    /* header --- */
    printf("# mu         lambda       DKL avg");
    if(o_verbose>0)
      printf("      DKL st.dev.");
    if(o_verbose>1)
      printf("  T.");
    printf("\n");	
    /* ---------- */
    for (unsigned int i=0;i<gridmu;i++){
      for (unsigned int j=0;j<gridlambda;j++){
	mu = minmu+(maxmu-minmu)*i/(gridmu-1);
	lambda = minlambda+(maxlambda-minlambda)*j/(gridlambda -1);
	T=DKLaverage(R,&DKLavg,&DKLstd,mu,lambda,pi1,pi2,pi,mc,o_verbose);
	printf("%e %e %e ",mu,lambda,DKLavg);
	if(o_verbose>0)
	  printf("%e ",DKLstd);
	if(o_verbose>1)
	  printf("%lu ",T);
	printf("\n");
      }
      printf("\n");
    }
  }
  
  /* free RNG */
  for (unsigned int i=0;i<mc.n;i++){    
    gsl_rng_free(R[i]);
  }
  free(R);

  return 0;
}
