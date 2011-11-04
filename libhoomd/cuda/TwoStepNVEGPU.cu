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

#include "TwoStepNVEGPU.cuh"

#ifdef WIN32
#include <cassert>
#else
#include <assert.h>
#endif

/*! \file TwoStepNVEGPU.cu
    \brief Defines GPU kernel code for NVE integration on the GPU. Used by TwoStepNVEGPU.
*/

//! Takes the first half-step forward in the velocity-verlet NVE integration on a group of particles
/*! \param pdata Particle data to step forward 1/2 step
    \param d_group_members Device array listing the indicies of the mebers of the group to integrate
    \param group_size Number of members in the group
    \param box Box dimensions for periodic boundary condition handling
    \param deltaT timestep
    \param limit If \a limit is true, then the dynamics will be limited so that particles do not move
        a distance further than \a limit_val in one step.
    \param limit_val Length to limit particle distance movement to
    \param zero_force Set to true to always assign an acceleration of 0 to all particles in the group
    
    This kernel must be executed with a 1D grid of any block size such that the number of threads is greater than or
    equal to the number of members in the group. The kernel's implementation simply reads one particle in each thread
    and updates that particle.
    
    <b>Performance notes:</b>
    Particle properties are read via the texture cache to optimize the bandwidth obtained with sparse groups. The writes
    in sparse groups will not be coalesced. However, because ParticleGroup sorts the index list the writes will be as
    contiguous as possible leading to fewer memory transactions on compute 1.3 hardware and more cache hits on Fermi.
*/
extern "C" __global__ 
void gpu_nve_step_one_kernel(gpu_pdata_arrays pdata,
                             unsigned int *d_group_members,
                             unsigned int group_size,
                             gpu_boxsize box,
                             float deltaT,
                             bool limit,
                             float limit_val,
                             bool zero_force)
    {
    // determine which particle this thread works on (MEM TRANSFER: 4 bytes)
    int group_idx = blockIdx.x * blockDim.x + threadIdx.x;
    
    if (group_idx < group_size)
        {
        unsigned int idx = d_group_members[group_idx];
    
        // do velocity verlet update
        // r(t+deltaT) = r(t) + v(t)*deltaT + (1/2)a(t)*deltaT^2
        // v(t+deltaT/2) = v(t) + (1/2)a*deltaT

        // read the particle's posision (MEM TRANSFER: 16 bytes)
        float4 pos = pdata.pos[idx];
        
        float px = pos.x;
        float py = pos.y;
        float pz = pos.z;
        float pw = pos.w;
        
        // read the particle's velocity and acceleration (MEM TRANSFER: 32 bytes)
        float4 vel = pdata.vel[idx];
        float4 accel = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
        if (!zero_force)
            accel = pdata.accel[idx];
        
        // update the position (FLOPS: 15)
        float dx = vel.x * deltaT + (1.0f/2.0f) * accel.x * deltaT * deltaT;
        float dy = vel.y * deltaT + (1.0f/2.0f) * accel.y * deltaT * deltaT;
        float dz = vel.z * deltaT + (1.0f/2.0f) * accel.z * deltaT * deltaT;
        
        // limit the movement of the particles
        if (limit)
            {
            float len = sqrtf(dx*dx + dy*dy + dz*dz);
            if (len > limit_val)
                {
                dx = dx / len * limit_val;
                dy = dy / len * limit_val;
                dz = dz / len * limit_val;
                }
            }
            
        // FLOPS: 3
        px += dx;
        py += dy;
        pz += dz;
        
        // update the velocity (FLOPS: 9)
        vel.x += (1.0f/2.0f) * accel.x * deltaT;
        vel.y += (1.0f/2.0f) * accel.y * deltaT;
        vel.z += (1.0f/2.0f) * accel.z * deltaT;
        
        // read in the particle's image (MEM TRANSFER: 16 bytes)
        int4 image = pdata.image[idx];
        
        // fix the periodic boundary conditions (FLOPS: 15)
        float x_shift = rintf(px * box.Lxinv);
        px -= box.Lx * x_shift;
        image.x += (int)x_shift;
        
        float y_shift = rintf(py * box.Lyinv);
        py -= box.Ly * y_shift;
        image.y += (int)y_shift;
        
        float z_shift = rintf(pz * box.Lzinv);
        pz -= box.Lz * z_shift;
        image.z += (int)z_shift;
        
        float4 pos2;
        pos2.x = px;
        pos2.y = py;
        pos2.z = pz;
        pos2.w = pw;
        
        // write out the results (MEM_TRANSFER: 48 bytes)
        pdata.pos[idx] = pos2;
        pdata.vel[idx] = vel;
        pdata.image[idx] = image;
        }
    }

/*! \param pdata Particle data to step forward 1/2 step
    \param d_group_members Device array listing the indicies of the mebers of the group to integrate
    \param group_size Number of members in the group
    \param box Box dimensions for periodic boundary condition handling
    \param deltaT timestep
    \param limit If \a limit is true, then the dynamics will be limited so that particles do not move
        a distance further than \a limit_val in one step.
    \param limit_val Length to limit particle distance movement to
    \param zero_force Set to true to always assign an acceleration of 0 to all particles in the group
    
    See gpu_nve_step_one_kernel() for full documentation, this function is just a driver.
*/
cudaError_t gpu_nve_step_one(const gpu_pdata_arrays &pdata,
                             unsigned int *d_group_members,
                             unsigned int group_size,
                             const gpu_boxsize &box,
                             float deltaT,
                             bool limit,
                             float limit_val,
                             bool zero_force)
    {
    // setup the grid to run the kernel
    int block_size = 256;
    dim3 grid( (group_size/block_size) + 1, 1, 1);
    dim3 threads(block_size, 1, 1);
    
    // run the kernel
    gpu_nve_step_one_kernel<<< grid, threads >>>(pdata, d_group_members, group_size, box, deltaT, limit, limit_val, zero_force);
    
    return cudaSuccess;
    }

//! Takes the first half-step forward in the velocity-verlet NVE integration on a group of particles
/*! \param pdata Particle data to step forward in time
    \param d_group_members Device array listing the indicies of the mebers of the group to integrate
    \param group_size Number of members in the group
    \param d_net_force Net force on each particle
    \param deltaT Amount of real time to step forward in one time step
    \param limit If \a limit is true, then the dynamics will be limited so that particles do not move
        a distance further than \a limit_val in one step.
    \param limit_val Length to limit particle distance movement to
    \param zero_force Set to true to always assign an acceleration of 0 to all particles in the group
    
    This kernel is implemented in a very similar manner to gpu_nve_step_one_kernel(), see it for design details.
*/
extern "C" __global__ 
void gpu_nve_step_two_kernel(gpu_pdata_arrays pdata,
                            unsigned int *d_group_members,
                            unsigned int group_size,
                            float4 *d_net_force,
                            float deltaT,
                            bool limit,
                            float limit_val,
                            bool zero_force)
    {
    // determine which particle this thread works on (MEM TRANSFER: 4 bytes)
    int group_idx = blockIdx.x * blockDim.x + threadIdx.x;
    
    if (group_idx < group_size)
        {
        unsigned int idx = d_group_members[group_idx];
        
        // read in the net forc and calculate the acceleration MEM TRANSFER: 16 bytes
        float4 accel = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
        if (!zero_force)
            {
            accel = d_net_force[idx];
            // MEM TRANSFER: 4 bytes   FLOPS: 3
            float mass = pdata.mass[idx];
            accel.x /= mass;
            accel.y /= mass;
            accel.z /= mass;
            }
        
        // v(t+deltaT) = v(t+deltaT/2) + 1/2 * a(t+deltaT)*deltaT
        // read the current particle velocity (MEM TRANSFER: 16 bytes)
        float4 vel = pdata.vel[idx];
        
        // update the velocity (FLOPS: 6)
        vel.x += (1.0f/2.0f) * accel.x * deltaT;
        vel.y += (1.0f/2.0f) * accel.y * deltaT;
        vel.z += (1.0f/2.0f) * accel.z * deltaT;
        
        if (limit)
            {
            float vel_len = sqrtf(vel.x*vel.x + vel.y*vel.y + vel.z*vel.z);
            if ( (vel_len*deltaT) > limit_val)
                {
                vel.x = vel.x / vel_len * limit_val / deltaT;
                vel.y = vel.y / vel_len * limit_val / deltaT;
                vel.z = vel.z / vel_len * limit_val / deltaT;
                }
            }
            
        // write out data (MEM TRANSFER: 32 bytes)
        pdata.vel[idx] = vel;
        // since we calculate the acceleration, we need to write it for the next step
        pdata.accel[idx] = accel;
        }
    }

/*! \param pdata Particle data to step forward in time
    \param d_group_members Device array listing the indicies of the mebers of the group to integrate
    \param group_size Number of members in the group
    \param d_net_force Net force on each particle
    \param deltaT Amount of real time to step forward in one time step
    \param limit If \a limit is true, then the dynamics will be limited so that particles do not move
        a distance further than \a limit_val in one step.
    \param limit_val Length to limit particle distance movement to
    \param zero_force Set to true to always assign an acceleration of 0 to all particles in the group

    This is just a driver for gpu_nve_step_two_kernel(), see it for details.
*/
cudaError_t gpu_nve_step_two(const gpu_pdata_arrays &pdata,
                             unsigned int *d_group_members,
                             unsigned int group_size,
                             float4 *d_net_force,
                             float deltaT,
                             bool limit,
                             float limit_val,
                             bool zero_force)
    {
    
    // setup the grid to run the kernel
    int block_size = 256;
    dim3 grid( (group_size/block_size) + 1, 1, 1);
    dim3 threads(block_size, 1, 1);
    
    // run the kernel
    gpu_nve_step_two_kernel<<< grid, threads >>>(pdata,
                                                 d_group_members,
                                                 group_size,
                                                 d_net_force,
                                                 deltaT,
                                                 limit,
                                                 limit_val,
                                                 zero_force);
    
    return cudaSuccess;
    }

