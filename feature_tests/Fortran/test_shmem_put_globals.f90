!
! Copyright (c) 2011, University of Houston System and Oak Ridge National
! Laboratory.
! 
! All rights reserved.
! 
! Redistribution and use in source and binary forms, with or without
! modification, are permitted provided that the following conditions
! are met:
! 
! o Redistributions of source code must retain the above copyright notice,
!   this list of conditions and the following disclaimer.
! 
! o Redistributions in binary form must reproduce the above copyright
!   notice, this list of conditions and the following disclaimer in the
!   documentation and/or other materials provided with the distribution.
! 
! o Neither the name of the University of Houston System, Oak Ridge
!   National Laboratory nor the names of its contributors may be used to
!   endorse or promote products derived from this software without specific
!   prior written permission.
! 
! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
! "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
! LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
! A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
! HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
! SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
! TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
! PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
! LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
! NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
! SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

! Calls tested
! shmem_integer_put, shmem_realput, shmem_double_put
! shmem_character_put, shmem_logical_put
! shmem_putmem, shmem_put32, shmem_put64
! 
! All PEs put an array on the right neighbor 

program test_shmem_put
  implicit none
  include 'mpp/shmem.fh'

  integer, parameter :: N = 7

  integer                 ::  i,j
  integer                 ::  nextpe
  integer                 ::  me, npes
  integer                 ::  success1,success2,success3, success4, success5, success6

  integer          , save :: dest1(N)
  real             , save :: dest2(N)
  double precision , save :: dest3(N)
  character        , save :: dest4(N)
  character        , save :: dest5(N)
  logical          , save :: dest6(N)
  integer*8        , save :: dest7(N)

  integer                 :: src1(N)
  real                    :: src2(N)
  double precision        :: src3(N)
  character               :: src4(N)
  character               :: src5(N)
  logical                 :: src6(N)
  integer*8               :: src7(N)

  integer                 :: length, errcode, abort

! Function definitions
  integer                   :: my_pe, num_pes  

  call start_pes(0)
  me   = my_pe();
  npes = num_pes();

! Make sure this job is running on at least 2 PEs
  if(npes .gt. 1) then

    success1 = 0
    success2 = 0
    success3 = 0
    success4 = 0
    success5 = 0
    success6 = 0

    length = N

    do i = 1, N, 1
      dest1(i) = -9
      dest2(i) = real(9)
      dest3(i) = dble(9)
      dest4(i) = char(9)
      dest5(i) = char(9)      
      dest6(i) = .false.
      dest7(i) = int(-9, KIND=8)
    end do 

    do i = 1, N, 1
      src1(i) = me
      src2(i) = real(me)
      src3(i) = dble(me)
      src4(i) = char(me)
      src5(i) = char(me)
      src6(i) = .true.
      src7(i) = int(me, KIND=8)
    end do 

    nextpe = mod((me + 1), npes)

    call shmem_barrier_all()

    call shmem_integer_put(dest1, src1, N, nextpe)
    call shmem_real_put(dest2, src2, N, nextpe)
    call shmem_double_put(dest3, src3, N, nextpe)
    call shmem_character_put(dest4, src4, N, nextpe)
    call shmem_putmem(dest5, src5, N, nextpe)
    call shmem_logical_put(dest6, src6, N, nextpe)

    call shmem_barrier_all()

    if(me .eq. 0) then
      do i = 1, N, 1
        if(dest1(i) .ne. (npes - 1)) then
          success1 = success1 + 1
        end if
        if(dest2(i) .ne. (npes - 1)) then
          success2 = success2 + 1
        end if
        if(dest3(i) .ne. (npes - 1)) then
          success3 = success3 + 1
        end if
        if(dest4(i) .ne. char(npes - 1)) then
          success4 = success4 + 1
        end if
        if(dest5(i) .ne. char(npes - 1)) then
          success5 = success5 + 1
        end if
        if(.not. dest6(i)) then
          success6 = success6 + 1
        end if
      end do 

      if(success1 .eq. 0) then
        write(*,*) "Test shmem_integer_put: Passed" 
      else
        write(*,*) "Test shmem_integer_put: Failed"
      end if
      if(success2 .eq. 0) then
        write(*,*) "Test shmem_real_put: Passed"  
      else
        write(*,*) "Test shmem_real_put: Failed"
      end if
      if(success3 .eq. 0) then
        write(*,*) "Test shmem_double_put: Passed"  
      else
        write(*,*) "Test shmem_double_put: Failed"
      end if
      if(success4 .eq. 0) then
        write(*,*) "Test shmem_character_put: Passed"  
      else
        write(*,*) "Test shmem_character_put: Failed"
      end if
      if(success5 .eq. 0) then
        write(*,*) "Test shmem_putmem: Passed"  
      else
        write(*,*) "Test shmem_putmem: Failed"
      end if
      if(success6 .eq. 0) then
        write(*,*) "Test shmem_logical_put: Passed"  
      else
        write(*,*) "Test shmem_logical_put: Failed"
      end if
    end if 

    call shmem_barrier_all()

    ! Testing shmem_put32, shmem_put64, shmem_put128 
    if(2 .eq. 2) then
      do i = 1, N, 1
        dest1(i) = -9
        dest7(i) = -9
      end do 

      success1 = 0

      call shmem_barrier_all()

      call shmem_put32(dest1, src1, N, nextpe)
      call shmem_put64(dest7, src7, N, nextpe)

      call shmem_barrier_all()

      if(me .eq. 0) then
        do i = 1, N, 1
          if(dest2(i) .ne. npes - 1) then
            success2 = success2 + 1
          end if
          if(dest7(i) .ne. npes - 1) then
            success3 = success3 + 1
          end if
        end do

        if(success2 .eq. 0) then
          write(*,*) "Test shmem_put32: Passed"  
        else
          write(*,*) "Test shmem_put32: Failed"
        end if

        if(success3 .eq. 0) then
          write(*,*) "Test shmem_put64: Passed" 
        else
          write(*,*) "Test shmem_put64: Failed"
        end if

      end if
    end if

    call shmem_barrier_all()

  else
    write(*,*) "Number of PEs must be > 1 to test shmem get, test skipped"
  end if
end program
