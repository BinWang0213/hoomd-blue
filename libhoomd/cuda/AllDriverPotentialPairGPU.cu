/*
Highly Optimized Object-oriented Many-particle Dynamics -- Blue Edition
(HOOMD-blue) Open Source Software License Copyright 2008, 2009 Ames Laboratory
Iowa State University and The Regents of the University of Michigan All rights
reserved.

HOOMD-blue may contain modifications ("Contributions") provided, and to which
copyright is held, by various Contributors who have granted The Regents of the
University of Michigan the right to modify and/or distribute such Contributions.

Redistribution and use of HOOMD-blue, in source and binary forms, with or
without modification, are permitted, provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions, and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions, and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of HOOMD-blue's
contributors may be used to endorse or promote products derived from this
software without specific prior written permission.

Disclaimer

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS ``AS IS''
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND/OR
ANY WARRANTIES THAT THIS SOFTWARE IS FREE OF INFRINGEMENT ARE DISCLAIMED.

IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// $Id$
// $URL$
// Maintainer: joaander / Everyone is free to add additional potentials

/*! \file AllDriverPotentialPairGPU.cu
    \brief Defines the driver functions for computing all types of pair forces on the GPU
*/

#include "EvaluatorPairLJ.h"
#include "EvaluatorPairGauss.h"
#include "EvaluatorPairSLJ.h"
#include "EvaluatorPairYukawa.h"
#include "EvaluatorPairMorse.h"
#include "PotentialPairDPDThermoGPU.cuh"
#include "EvaluatorPairDPDThermo.h"
#include "AllDriverPotentialPairGPU.cuh"

/*! This is just a driver function for gpu_compute_pair_forces<EvaluatorPairLJ>(). See it for details.

    \param force_data Device memory array to write calculated forces to
    \param pdata Particle data on the GPU to calculate forces on
    \param box Box dimensions used to implement periodic boundary conditions
    \param d_n_neigh Device memory array listing the number of neighbors for each particle
    \param d_nlist Device memory array containing the neighbor list contents
    \param nli Indexer for indexing \a d_nlist
    \param d_params Parameters for the potential, stored per type pair
    \param d_rcutsq rcut squared, stored per type pair
    \param d_ronsq ron squared, stored per type pair
    \param ntypes Number of types in the simulation
    \param block_size Block size to execute on the GPU
    \param shift_mode Energy shift mode to apply to the potential calculation
*/
cudaError_t gpu_compute_ljtemp_forces(const gpu_force_data_arrays& force_data,
                                      const gpu_pdata_arrays &pdata,
                                      const gpu_boxsize &box,
                                      const unsigned int *d_n_neigh,
                                      const unsigned int *d_nlist,
                                      const Index2D& nli,
                                      const float2 *d_params,
                                      const float *d_rcutsq,
                                      const float *d_ronsq,
                                      const unsigned int ntypes,
                                      const unsigned int block_size,
                                      const unsigned int shift_mode)
    {
    return gpu_compute_pair_forces<EvaluatorPairLJ>(force_data,
                                                    pdata,
                                                    box,
                                                    d_n_neigh,
                                                    d_nlist,
                                                    nli,
                                                    d_params,
                                                    d_rcutsq,
                                                    d_ronsq,
                                                    ntypes,
                                                    block_size,
                                                    shift_mode);
    }

/*! This is just a driver function for gpu_compute_pair_forces<EvaluatorPairGauss>(). See it for details.

    \param force_data Device memory array to write calculated forces to
    \param pdata Particle data on the GPU to calculate forces on
    \param box Box dimensions used to implement periodic boundary conditions
    \param d_n_neigh Device memory array listing the number of neighbors for each particle
    \param d_nlist Device memory array containing the neighbor list contents
    \param nli Indexer for indexing \a d_nlist
    \param d_params Parameters for the potential, stored per type pair
    \param d_rcutsq rcut squared, stored per type pair
    \param d_ronsq ron squared, stored per type pair
    \param ntypes Number of types in the simulation
    \param block_size Block size to execute on the GPU
    \param shift_mode Energy shift mode to apply to the potential calculation

*/
cudaError_t gpu_compute_gauss_forces(const gpu_force_data_arrays& force_data,
                                     const gpu_pdata_arrays &pdata,
                                     const gpu_boxsize &box,
                                     const unsigned int *d_n_neigh,
                                     const unsigned int *d_nlist,
                                     const Index2D& nli,
                                     const float2 *d_params,
                                     const float *d_rcutsq,
                                     const float *d_ronsq,
                                     const unsigned int ntypes,
                                     const unsigned int block_size,
                                     const unsigned int shift_mode)
    {
    return gpu_compute_pair_forces<EvaluatorPairGauss>(force_data,
                                                       pdata,
                                                       box,
                                                       d_n_neigh,
                                                       d_nlist,
                                                       nli,
                                                       d_params,
                                                       d_rcutsq,
                                                       d_ronsq,
                                                       ntypes,
                                                       block_size,
                                                       shift_mode);
    }

/*! This is just a driver function for gpu_compute_pair_forces<EvaluatorPairSLJ>(). See it for details.

    \param force_data Device memory array to write calculated forces to
    \param pdata Particle data on the GPU to calculate forces on
    \param box Box dimensions used to implement periodic boundary conditions
    \param d_n_neigh Device memory array listing the number of neighbors for each particle
    \param d_nlist Device memory array containing the neighbor list contents
    \param nli Indexer for indexing \a d_nlist
    \param d_params Parameters for the potential, stored per type pair
    \param d_rcutsq rcut squared, stored per type pair
    \param d_ronsq ron squared, stored per type pair
    \param ntypes Number of types in the simulation
    \param block_size Block size to execute on the GPU
    \param shift_mode Energy shift mode to apply to the potential calculation

*/
cudaError_t gpu_compute_slj_forces(const gpu_force_data_arrays& force_data,
                                   const gpu_pdata_arrays &pdata,
                                   const gpu_boxsize &box,
                                   const unsigned int *d_n_neigh,
                                   const unsigned int *d_nlist,
                                   const Index2D& nli,
                                   const float2 *d_params,
                                   const float *d_rcutsq,
                                   const float *d_ronsq,
                                   const unsigned int ntypes,
                                   const unsigned int block_size,
                                   const unsigned int shift_mode)
    {
    return gpu_compute_pair_forces<EvaluatorPairSLJ>(force_data,
                                                     pdata,
                                                     box,
                                                     d_n_neigh,
                                                     d_nlist,
                                                     nli,
                                                     d_params,
                                                     d_rcutsq,
                                                     d_ronsq,
                                                     ntypes,
                                                     block_size,
                                                     shift_mode);
    }

/*! This is just a driver function for gpu_compute_pair_forces<EvaluatorPairYukawa>(). See it for details.

    \param force_data Device memory array to write calculated forces to
    \param pdata Particle data on the GPU to calculate forces on
    \param box Box dimensions used to implement periodic boundary conditions
    \param d_n_neigh Device memory array listing the number of neighbors for each particle
    \param d_nlist Device memory array containing the neighbor list contents
    \param nli Indexer for indexing \a d_nlist
    \param d_params Parameters for the potential, stored per type pair
    \param d_rcutsq rcut squared, stored per type pair
    \param d_ronsq ron squared, stored per type pair
    \param ntypes Number of types in the simulation
    \param block_size Block size to execute on the GPU
    \param shift_mode Energy shift mode to apply to the potential calculation

*/
cudaError_t gpu_compute_yukawa_forces(const gpu_force_data_arrays& force_data,
                                      const gpu_pdata_arrays &pdata,
                                      const gpu_boxsize &box,
                                      const unsigned int *d_n_neigh,
                                      const unsigned int *d_nlist,
                                      const Index2D& nli,
                                      const float2 *d_params,
                                      const float *d_rcutsq,
                                      const float *d_ronsq,
                                      const unsigned int ntypes,
                                      const unsigned int block_size,
                                      const unsigned int shift_mode)
    {
    return gpu_compute_pair_forces<EvaluatorPairYukawa>(force_data,
                                                        pdata,
                                                        box,
                                                        d_n_neigh,
                                                        d_nlist,
                                                        nli,
                                                        d_params,
                                                        d_rcutsq,
                                                        d_ronsq,
                                                        ntypes,
                                                        block_size,
                                                        shift_mode);
    }

/*! This is just a driver function for gpu_compute_pair_forces<EvaluatorPairMorse>(). See it for details.

    \param force_data Device memory array to write calculated forces to
    \param pdata Particle data on the GPU to calculate forces on
    \param box Box dimensions used to implement periodic boundary conditions
    \param d_n_neigh Device memory array listing the number of neighbors for each particle
    \param d_nlist Device memory array containing the neighbor list contents
    \param nli Indexer for indexing \a d_nlist
    \param d_params Parameters for the potential, stored per type pair
    \param d_rcutsq rcut squared, stored per type pair
    \param d_ronsq ron squared, stored per type pair
    \param ntypes Number of types in the simulation
    \param block_size Block size to execute on the GPU
    \param shift_mode Energy shift mode to apply to the potential calculation

*/
cudaError_t gpu_compute_morse_forces(const gpu_force_data_arrays& force_data,
                                     const gpu_pdata_arrays &pdata,
                                     const gpu_boxsize &box,
                                     const unsigned int *d_n_neigh,
                                     const unsigned int *d_nlist,
                                     const Index2D& nli,
                                     const float4 *d_params,
                                     const float *d_rcutsq,
                                     const float *d_ronsq,
                                     const unsigned int ntypes,
                                     const unsigned int block_size,
                                     const unsigned int shift_mode)
    {
    return gpu_compute_pair_forces<EvaluatorPairMorse>(force_data,
                                                       pdata,
                                                       box,
                                                       d_n_neigh,
                                                       d_nlist,
                                                       nli,
                                                       d_params,
                                                       d_rcutsq,
                                                       d_ronsq,
                                                       ntypes,
                                                       block_size,
                                                       shift_mode);
    }
/*! This is just a driver function for gpu_compute_dpd_forces<EvaluatorPairDPDThermo>(). See it for details.

    \param force_data Device memory array to write calculated forces to
    \param pdata Particle data on the GPU to calculate forces on
    \param box Box dimensions used to implement periodic boundary conditions
    \param nlist Neigbhor list data on the GPU to use to calculate the forces
    \param d_params Parameters for the potential, stored per type pair
    \param d_rcutsq rcut squared, stored per type pair
    \param ntypes Number of types in the simulation
    \param args Additional arguments specific to DPD 
*/
cudaError_t gpu_compute_dpdthermodpd_forces(const gpu_force_data_arrays& force_data,
                                      const gpu_pdata_arrays &pdata,
                                      const gpu_boxsize &box,
                                      const gpu_nlist_array &nlist,
                                      float2 *d_params,
                                      float *d_rcutsq,
                                      int ntypes,
                                      const dpd_pair_args& args)
    {
    return gpu_compute_dpd_forces<EvaluatorPairDPDThermo>(force_data,
                                                    pdata,
                                                    box,
                                                    nlist,
                                                    d_params,
                                                    d_rcutsq,
                                                    ntypes,
                                                    args);
    }                                          


/*! This is just a driver function for gpu_compute_forces<EvaluatorPairDPDThermo>(). See it for details.

    \param force_data Device memory array to write calculated forces to
    \param pdata Particle data on the GPU to calculate forces on
    \param box Box dimensions used to implement periodic boundary conditions
    \param nlist Neigbhor list data on the GPU to use to calculate the forces
    \param d_params Parameters for the potential, stored per type pair
    \param d_rcutsq rcut squared, stored per type pair
    \param d_ronsq ron squared, stored per type pair
    \param ntypes Number of types in the simulation
    \param args Additional arguments
*/
cudaError_t gpu_compute_dpdthermo_forces(const gpu_force_data_arrays& force_data,
                                      const gpu_pdata_arrays &pdata,
                                      const gpu_boxsize &box,
                                      const gpu_nlist_array &nlist,
                                      float2 *d_params,
                                      float *d_rcutsq,
                                      float *d_ronsq,
                                      int ntypes,
                                      const pair_args& args)
    {
    return gpu_compute_pair_forces<EvaluatorPairDPDThermo>(force_data,
                                                    pdata,
                                                    box,
                                                    nlist,
                                                    d_params,
                                                    d_rcutsq,
                                                    d_ronsq,
                                                    ntypes,
                                                    args);
    }   

