
/* set the number of rows and column here */ 
#define ROWS 800 
#define COLUMNS 800 

// needed for reduction operation
long pSync[_SHMEM_REDUCE_SYNC_SIZE];
double pWrk[_SHMEM_REDUCE_MIN_WRKDATA_SIZE];

int
main (int argc, char **argv) 
{
  int i;
  int rank, np, blocksize, B_matrix_displacement;
  for (i = 0; i < _SHMEM_REDUCE_SYNC_SIZE; i += 1)
    pSync[i] = _SHMEM_SYNC_VALUE;

  start_pes(0);
  rank = _my_pe ();
  np = _num_pes ();
  blocksize = COLUMNS / np;	// block size
  B_matrix_displacement = rank * blocksize;

    // initialize the input arrays
    shmem_barrier_all ();
  a_local = (double **) shmalloc (ROWS * sizeof (double *));
  b_local = (double **) shmalloc (ROWS * sizeof (double *));
  c_local = (double **) shmalloc (ROWS * sizeof (double *));
  for (i = 0; i < ROWS; i++) {
    a_local[i] = (double *) shmalloc (blocksize * sizeof (double));
    b_local[i] = (double *) shmalloc (blocksize * sizeof (double));
    c_local[i] = (double *) shmalloc (blocksize * sizeof (double));
    for (j = 0; j < blocksize; j++) {
      a_local[i][j] = i + 1 * j + 1 * rank + 1;	// random values
      b_local[i][j] = i + 2 * j + 2 * rank + 1;	// random values
      c_local[i][j] = 0.0;
    }
  }
  shmem_barrier_all ();

  // start the matrix multiplication
  for (i = 0; i < ROWS; i++) {
    for (p = 1; p <= np; p++) {
	    // compute the partial product of c[i][j]
      localcomp(a_local[i], b_local, c_local[i], blocksize, B_matrix_displacement);
	  
	    // send a block of matrix A to the adjacent PE
	    shmem_barrier_all ();
      if (rank == np - 1)
        shmem_double_put (&a_local[i][0], &a_local[i][0], blocksize, 0);
	    else
        shmem_double_put (&a_local[i][0], &a_local[i][0], blocksize,
			       rank + 1);
      shmem_barrier_all ();
	  
	    // reset the displacement of matrix B to the next block
	    if (B_matrix_displacement == 0)
        B_matrix_displacement = (np - 1) * blocksize;
	    else
        B_matrix_displacement = B_matrix_displacement - blocksize;
		}
  }
  return 0;
}

void localcomp(double* amatrix, double** bmatrix, 
              double* cmaxtrix, int size, int offset) {
  int k, j;
  for (k = 0; k < size; k++) {
    for (j = 0; j < size; j++) {
      cmaxtrix[j] = cmaxtrix[j] + amatrix[k] 
        *bmatrix[k + offset][j];
    }
  }
}

void remotecomp() {
  int rank, np;
  rank = _my_pe ();
  np = _num_pes ();

  // send a block of matrix A to the adjacent PE
  shmem_barrier_all ();
  if (rank == np - 1)
    shmem_double_put (&a_local[i][0], &a_local[i][0], blocksize, 0);
  else
    shmem_double_put (&a_local[i][0], &a_local[i][0], blocksize,
         rank + 1);
  shmem_barrier_all ();

  // reset the displacement of matrix B to the next block
  if (B_matrix_displacement == 0)
    B_matrix_displacement = (np - 1) * blocksize;
  else
    B_matrix_displacement = B_matrix_displacement - blocksize;
}