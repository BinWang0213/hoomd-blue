/*
Highly Optimized Object-oriented Many-particle Dynamics -- Blue Edition
(HOOMD-blue) Open Source Software License Copyright 2008-2011 Ames Laboratory
Iowa State University and The Regents of the University of Michigan All rights
reserved.

HOOMD-blue may contain modifications ("Contributions") provided, and to which
copyright is held, by various Contributors who have granted The Regents of the
University of Michigan the right to modify and/or distribute such Contributions.

You may redistribute, use, and create derivate works of HOOMD-blue, in source
and binary forms, provided you abide by the following conditions:

* Redistributions of source code must retain the above copyright notice, this
list of conditions, and the following disclaimer both in the code and
prominently in any materials provided with the distribution.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions, and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* All publications based on HOOMD-blue, including any reports or published
results obtained, in whole or in part, with HOOMD-blue, will acknowledge its use
according to the terms posted at the time of submission on:
http://codeblue.umich.edu/hoomd-blue/citations.html

* Any electronic documents citing HOOMD-Blue will link to the HOOMD-Blue website
at: http://codeblue.umich.edu/hoomd-blue/.

* Apart from the above required attributions, neither the name of the copyright
holder nor the names of HOOMD-blue's contributors may be used to endorse or
promote products derived from this software without specific prior written
permission.

Disclaimer

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND/OR ANY
WARRANTIES THAT THIS SOFTWARE IS FREE OF INFRINGEMENT ARE DISCLAIMED.

IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Maintainer: joaander

#ifndef _BONDDATA_CUH_
#define _BONDDATA_CUH_

#include <cuda_runtime.h>

/*! \file BondData.cuh
    \brief GPU data structures used in BondData
*/

//! Bond data stored on the GPU
/*! gpu_bondtable_array stores all of the bonds between particles on the GPU.
    It is structured similar to gpu_nlist_array in that a single column in the list
    stores all of the bonds for the particle associated with that column.

    To access bond \em b of particle with local index \em i, use the following indexing scheme
    \code
    uint2 bond = bondtable.bonds[b*bondtable.pitch + i]
    \endcode
    The particle with \b index (not tag) \em i is bonded to particle \em bond.x
    with bond type \em bond.y. Each particle may have a different number of bonds as
    indicated in \em n_bonds[i].

    Only \a num_local bonds are stored on each GPU for the local particles

    \ingroup gpu_data_structs
*/
struct gpu_bondtable_array
    {
    unsigned int *n_bonds;  //!< Number of bonds for each particle
    uint2 *bonds;           //!< bond list
    unsigned int height;    //!< height of the bond list
    unsigned int pitch;     //!< width (in elements) of the bond list
    
    //! Allocates memory
    cudaError_t allocate(unsigned int num_local, unsigned int alloc_height);
    
    //! Frees memory
    cudaError_t deallocate();
    };

#endif

