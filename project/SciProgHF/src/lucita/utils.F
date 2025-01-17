!      Copyright (c) 2019 by the authors of DIRAC.
!      All Rights Reserved.
!
!      This source code is part of the DIRAC program package.
!      It is provided under a written license and may be used,
!      copied, transmitted, or stored only in accordance to the
!      conditions of that written license.
!
!      In particular, no part of the source code or compiled modules may
!      be distributed outside the research group of the license holder.
!      This means also that persons (e.g. post-docs) leaving the research
!      group of the license holder may not take any part of Dirac,
!      including modified files, with him/her, unless that person has
!      obtained his/her own license.
!
!      For information on how to get a license, as well as the
!      author list and the complete list of contributors to the
!      DIRAC program, see: http://www.diracprogram.org

***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
*  Dummy routine
      subroutine add_info(ECI,FINEIG,NROOT)
      implicit none
      character*4 ECI
      real*8 FINEIG
      integer NROOT
      return
      end
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      SUBROUTINE CHAR_TO_INTEGER(CHAR_X,INT_X)

*     Convert an integer number given as a string into
*     an integer variable

      CHARACTER*72 CHAR_X
      INTEGER      INT_X
      CHARACTER*12 STRING

      CALL STDFMT(CHAR_X,STRING)
      READ (STRING,'(I12)',IOSTAT=IOS,ERR=100,END=200) INT_X
      RETURN

100   WRITE (*,*)
      WRITE (*,*) ' *** ERROR IN INPUT ***'
      WRITE (*,*) ' THE PROGRAM EXPECTED AN INTEGER NUMBER'
      WRITE (*,*) ' BUT WAS SUPPLIED WITH A REAL NUMBER OR'
      WRITE (*,*) ' A CHARACTER STRING'
      WRITE (*,*)
      WRITE (*,*) ' FORTRAN I/O STATUS = ',IOS
      WRITE (*,*)
      WRITE (*,*) ' THE LAST LINE PROCESSED WAS:'
      WRITE (*,*) CHAR_X
      WRITE (*,*)
      CALL QUIT(16)

200   WRITE (*,*)
      WRITE (*,*) ' *** ERROR IN INPUT ***'
      WRITE (*,*) ' THE PROGRAM EXPECTED AN INTEGER NUMBER'
      WRITE (*,*) ' BUT WAS SUPPLIED WITH AN EMPTY CHARACTER STRING'
      WRITE (*,*)
      WRITE (*,*) ' FORTRAN I/O STATUS = ',IOS
      WRITE (*,*)
      CALL QUIT(16)

      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      SUBROUTINE CHAR_TO_INTEGER_MOLUC(CHAR_X,INT_X)
*
      IMPLICIT REAL*8(A-H,O-Z)
      CHARACTER*72 CHAR_X
      INTEGER FLLNGTH
      CHARACTER*10 SCRFLL
      CHARACTER*6 SCRFL

*
#include "units.inc"
#if defined (VAR_MPI2)
#include "mpif.h"
#include "infpar.h"
      INTEGER   ISTAT(MPI_STATUS_SIZE)
#include "parluci.h"
#endif
      

*
      NTESTL = 0
      if (NTESTL.ge.1) then
        write(6,*) ' INFO FROM CHAR_TO_INTEGER'
        write(6,'(A)') ' CHARACTER INPUT ', CHAR_X
      end if
*
      LU_INTERNAL = LUSC_INT
      SCRFL ="LUSCDL"
*
#if defined (VAR_MPI2)
      IF (MYPROC .LT. 10) THEN    ! MPI ID has one digit
         WRITE (SCRFLL,'(A6,A1,I1)') SCRFL,'.',MYPROC
         FLLNGTH=8
      ELSEIF (MYPROC .LT. 100) THEN  ! MPI ID has two digits
         WRITE (SCRFLL,'(A6,A1,I2)') SCRFL,'.',MYPROC
         FLLNGTH=9
      ELSEIF (MYPROC .LT. 1000) THEN  ! MPI ID has three digits
         WRITE (SCRFLL,'(A6,A1,I3)') SCRFL,'.',MYPROC
         FLLNGTH=10
      ELSE
         CALL QUIT("NMPROC.GT.1000! EXTEND LUCI*_NODE MODULE")
      ENDIF
#else
      SCRFLL=SCRFL
      FLLNGTH=6
#endif

      Open(Unit=LU_INTERNAL,
     &     File=SCRFLL(1:FLLNGTH),
     &     Status='NEW',
     &     Form='FORMATTED')
*
      REWIND(LU_INTERNAL)
      WRITE(LU_INTERNAL,'(A)') CHAR_X
      REWIND(LU_INTERNAL)
      READ(LU_INTERNAL,*) INT_X
*
      Close(Unit=LU_INTERNAL,
     &      Status='DELETE')
*
      if (NTESTL.ge.1) then
        write(6,*) ' INTEGER OUTPUT ', INT_X
      end if
*
      RETURN
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      SUBROUTINE CHAR_TO_REAL(CHAR_X,REAL_X)

*     Convert a real number given as a string into
*     a real variable

      CHARACTER*72 CHAR_X
      REAL*8       REAL_X
      CHARACTER*12 STRING

      CALL STDFMT(CHAR_X,STRING)
      READ (STRING,'(F18.10)',IOSTAT=IOS,ERR=100,END=200) REAL_X
      RETURN

100   WRITE (*,*)
      WRITE (*,*) ' *** ERROR IN INPUT ***'
      WRITE (*,*) ' THE PROGRAM EXPECTED A REAL NUMBER'
      WRITE (*,*) ' BUT WAS SUPPLIED WITH AN INTEGER NUMBER OR'
      WRITE (*,*) ' A CHARACTER STRING'
      WRITE (*,*)
      WRITE (*,*) ' FORTRAN I/O STATUS = ',IOS
      WRITE (*,*)
      WRITE (*,*) ' THE LAST LINE PROCESSED WAS:'
      WRITE (*,*) CHAR_X
      WRITE (*,*)
      CALL QUIT(16)

200   WRITE (*,*)
      WRITE (*,*) ' *** ERROR IN INPUT ***'
      WRITE (*,*) ' THE PROGRAM EXPECTED A REAL NUMBER'
      WRITE (*,*) ' BUT WAS SUPPLIED WITH AN EMPTY CHARACTER STRING'
      WRITE (*,*)
      WRITE (*,*) ' FORTRAN I/O STATUS = ',IOS
      WRITE (*,*)
      CALL QUIT(16)

      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      SUBROUTINE DECODE_LINE(LINE,NCHAR,NENTRY,IENTRY,MXENTRY)
*
* A CHAR line is given.
* Find number of separate items, with each item
* being separated by a ,
*
* Jeppe Olsen, Someday in 97 where I really should be doing more
* important things
*
*. Entry
      CHARACTER*(*) LINE
*. Output
      CHARACTER*72 IENTRY(MXENTRY)
*. Local scratch
      CHARACTER*72 CSCR
*
      LOGICAL :: LINE_ICHAR_CHECK
*
      JITEM=0
      JEFF = 0
      LINE_ICHAR_CHECK=.FALSE.
      DO ICHAR = 0, NCHAR
!miro: fix of "Fortran runtime error: Substring out of bounds: lower bound (0) of 'line' is less than one"
        IF (ICHAR.GT.0) LINE_ICHAR_CHECK=(LINE(ICHAR:ICHAR).EQ.',')
        !IF(ICHAR.EQ.0.OR.LINE(ICHAR:ICHAR).EQ.',') THEN
        IF(ICHAR.EQ.0.OR.LINE_ICHAR_CHECK) THEN
*Start of new item, make sure there is space and clean up
          JITEM = JITEM + 1
          IF(JITEM .GT.MXENTRY) THEN
            WRITE(6,*) 'DECODE_LINE:MXENTRY too small'
            WRITE(6,*) ' Number of entries larger than MXENTRY'
            WRITE(6,*) ' JITEM, MXENTRY', JITEM, MXENTRY
            Call Abend2( 'DECODE_LINE:MXENTRY too small' )
          END IF
*. Copy previous entry to permanent
          IF(JITEM.NE.1) THEN
            IENTRY(JITEM-1) = CSCR
          END IF
*. and clean
          DO JCHAR = 1, NCHAR
            CSCR(JCHAR:JCHAR) = ' '
          END DO
          JEFF = 0
        ELSE
*. Continuation of previous item
          JEFF = JEFF + 1
          CSCR(JEFF:JEFF) = LINE(ICHAR:ICHAR)
        END IF
*
      END DO
*. Transfer last item to permanant residence
      IF(JEFF.NE.0) IENTRY(JITEM) = CSCR
*
      NENTRY = JITEM
*
      NTEST = 000
      IF(NTEST.GE.100) THEN
        WRITE(6,*) ' Output from Decode line '
        WRITE(6,*) ' ========================'
        WRITE(6,*)
        WRITE(6,*) ' Number of separate entries', NENTRY
        WRITE(6,*)
        DO JENTRY = 1, NENTRY
          WRITE(6,'(A,I3,72A)') 'Entry ',JENTRY,IENTRY(JENTRY)
        END DO
      END IF
*
      RETURN
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      subroutine finish(IDUMMY)
      implicit none
      integer IDUMMY
      return
      end
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      FUNCTION IFRMR(WORK,IROFF,IELMNT)
*
* An integer array is stored in real array WORK,
* starting from WORK(IROFF). Obtain element
* IELMNT of this array
*
      INTEGER WORK(*)
*
#include "irat.inc"
*. offset when work is integer array
      IIOFF = 1 + IRAT * (IROFF-1)
      IFRMR = WORK(IIOFF-1+IELMNT)
*
      RETURN
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      FUNCTION IMNMX(IVEC,NDIM,MINMAX)
*
*     Find smallest (MINMAX=1) or largest (MINMAX=2)
*     absolute value of elements in integer vector IVEC
*
      DIMENSION IVEC(*) ! Miro: instead of IVEC(1)
*
      IF(NDIM.GT.0) THEN
        IX = -1
        IF(MINMAX.EQ.1) THEN
          IX=ABS(IVEC(1))
          DO I=2,NDIM
            IX=MIN(IX,ABS(IVEC(I)))
          END DO
        END IF
*
        IF(MINMAX.EQ.2) THEN
          IX=ABS(IVEC(1))
          DO I=2,NDIM
            IX=MAX(IX,ABS(IVEC(I)))
          END DO
        END IF
*
        IMNMX = IX
*
      ELSE IF(NDIM.EQ.0) THEN
*. No components : set to zero and write a warning
        IMNMX = 0
        WRITE(6,*) ' Min/Max taken zero length vector set to zero'
      END IF
*
      RETURN
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      SUBROUTINE NXTNUM2_REV(INUM,NELMNT,MINVAL,MAXVAL,NONEW)
*
* An set of numbers INUM(I),I=1,NELMNT is
* given. Find next compund number.
* Digit I must be in the range MINVAL,MAXVAL(I).
*
* In this version rightmost digits are increased first
*
* NONEW = 1 on return indicates that no additional numbers
* could be obtained.
*
* Jeppe Olsen March 1998
*
*. Input
      DIMENSION MAXVAL(*)
*. Input and output
      DIMENSION INUM(*)
*
       NTEST = 0
       IF( NTEST .NE. 0 ) THEN
         WRITE(6,*) ' Initial number in NXTNUM '
         CALL IWRTMA(INUM,1,NELMNT,1,NELMNT)
       END IF
*
      IF(NELMNT.EQ.0) THEN
       NONEW = 1
       GOTO 1001
      END IF
*
      IPLACE = NELMNT + 1
 1000 CONTINUE
        IPLACE = IPLACE - 1
        IF(INUM(IPLACE).LT.MAXVAL(IPLACE)) THEN
          INUM(IPLACE) = INUM(IPLACE) + 1
          NONEW = 0
          GOTO 1001
        ELSE IF ( IPLACE.GT.1 ) THEN
          INUM(IPLACE) = 1
        ELSE IF ( IPLACE. EQ. 1 ) THEN
          NONEW = 1
          GOTO 1001
        END IF
      GOTO 1000
 1001 CONTINUE
*
      IF( NTEST .NE. 0 ) THEN
        WRITE(6,*) ' New number '
        CALL IWRTMA(INUM,1,NELMNT,1,NELMNT)
      END IF
*
      RETURN
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      SUBROUTINE ORDINT(IINST,IOUTST,NELMNT,INO,IPRNT)
*
* ORDER A STRING OF INTEGERS TO ASCENDING ORDER
*
* IINST : INPUT STRING
* IOUTST : OUTPUT STRING
* NELMNT : NUMBER OF INTEGERS
* INO : Mapping array from new to old order
*
* THIS CODE CONTAINS THE OLD ORDER CODE OF JOE GOLAB
* ( HE IS HEREBY AKNOWLEDGED , AND I AM EXCUSED )
*
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION IINST(NELMNT),IOUTST(NELMNT),INO(NELMNT)
*
      IF(NELMNT.EQ.0) GOTO 1001
      CALL ICOPVE(IINST,IOUTST,NELMNT)
      DO  5 I = 1, NELMNT
        INO(I) = I
    5 CONTINUE
C
C       BEGIN TO ORDER
C
        JOE = 1
  10    I = JOE
  20    CONTINUE
        IF(I.EQ.NELMNT) GO TO 50
        IF(IOUTST(I).LE.IOUTST(I+1)) GO TO 40
        JOE = I + 1
  30    SWAP = IOUTST(I)
        IOUTST(I) = IOUTST(I+1)
        IOUTST(I+1) = SWAP
        ISWAP = INO(I)
        INO(I) = INO(I+1)
        INO(I+1) = ISWAP
        IF(I.EQ.1) GO TO 10
        I = I - 1
        IF(IOUTST(I).GT.IOUTST(I+1)) GO TO 30
        GO TO 10
 40     I = I + 1
      GO TO 20
C
C     END ORDER
C
 50   CONTINUE
*
 1001 CONTINUE
      NTEST = 000
      NTEST = MAX(NTEST,IPRNT)
      IF( NTEST .GE.200) THEN
        WRITE(6,*) ' Result from ORDINT '
        WRITE(6,*)
        WRITE(6,*)  ' Input string '
        CALL IWRTMA(IINST,1,NELMNT,1,NELMNT)
        WRITE(6,*)  ' Ordered string '
        CALL IWRTMA(IOUTST,1,NELMNT,1,NELMNT)
        WRITE(6,*) ' New to old order '
        CALL IWRTMA(INO,1,NELMNT,1,NELMNT)
      END IF
*
      RETURN
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
*  Dummy routine for normal compilations
*
      subroutine rdnlst
      read(5,*)
      return
      end
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      FUNCTION SCALAR_PRODUCT_OF_B
     &(VEC1,VEC2,NBLOCK1,IBLOCK1,I2EQ1,NBLOCK2,I2TO1,IOFF)
*
* Two blocked vectors VEC1 and VEC2 are given.
* VEC1 contains NBLOCK1 blocks defined by IBLOCK1.
* If I2EQ1.ne.0  VEC2 has the same block structure as VEC1
* IF I2EQ1 .eq.0 VEC2 contains NBLOCK2 blocks, and I2TO1 gives
* the mapping from blocks of VEC2 to blocks of vec1
*
* Find the scalar product between these two vectors
*
* Jeppe Olsen, October 1995
*
      IMPLICIT REAL*8(A-H,O-Z)
*
      DIMENSION VEC1(*),VEC2(*),IBLOCK1(8,*)
      REAL*8 INPROD
*. In use of I2EQ1 = 0
      DIMENSION I2TO1(*)
*
      X = 0.0D0
      IOFF2 = 1
      DO JBLOCK = 1, NBLOCK2
        IF(I2EQ1.NE.0) THEN
          JJBLOCK = JBLOCK-1+IOFF
          IOFF1   = IBLOCK1(6,JJBLOCK)
          IOFF2   = IOFF1
        ELSE
          JJBLOCK = I2TO1(JBLOCK)
          IOFF1 = IBLOCK1(6,JJBLOCK)
        END IF
        NELMNT = IBLOCK1(8,JJBLOCK)
        X = X + INPROD(VEC1(IOFF1),VEC2(IOFF2),NELMNT)
        IF(I2EQ1.EQ.0) IOFF2 = IOFF2 + NELMNT
      END DO
      SCALAR_PRODUCT_OF_B = X
*
      NTEST = 00
      IF(NTEST.GE.100) THEN
         WRITE(6,*) ' Output from INNER_PRODUCT_OF_BLOCKED_VECTORS'
         WRITE(6,*)
         WRITE(6,*) ' Number of blocks included ', NBLOCK2
         WRITE(6,*) ' Inner product ', X
      END IF
*
      RETURN
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      SUBROUTINE SQRTMT(A,NDIM,ITASK,ASQRT,AMSQRT,SCR)
*
* Calculate square root of positive definite symmetric matrix A
* if(ITASK .EQ. 2 ) Inverted square root matrix is also calculated
* In case of singularities in A A -1/2 is defined to have the same
* singularity
      IMPLICIT DOUBLE PRECISION( A-H,O-Z)
*
      DIMENSION A(NDIM,NDIM)
      DIMENSION ASQRT(NDIM,NDIM),AMSQRT(NDIM,NDIM)
      DIMENSION SCR(*)
* Length of SCR should at least be 2 * NDIM ** 2 + NDIM*(NDIM+1)/2
      KLFREE = 1
*
      KLASYM = KLFREE
      KLAVAL = KLASYM
      KLFREE = KLASYM + NDIM*(NDIM+1)/2
*
      KLAVEC = KLFREE
      KLFREE = KLFREE + NDIM ** 2
*
      NTEST = 0
*
C          TRIPAK(AUTPAK,APAK,IWAY,MATDIM,NDIM,SIGNTP)
      SIGNTP = 1.0
      CALL TRIPAK(A,SCR(KLASYM),1,NDIM,NDIM,SIGNTP)
      CALL EIGEN(SCR(KLASYM),SCR(KLAVEC),NDIM,0,1)
      CALL COPDIA(SCR(KLASYM),SCR(KLAVAL),NDIM,1)
      IF( NTEST .GE. 1 ) THEN
        WRITE(6,*) ' Eigenvalues of matrix : '
        CALL WRTMAT(SCR(KLAVAL),NDIM,1,NDIM,1)
      END IF
*. Check for negative eigenvalues
      DO I = 1, NDIM
       IF(SCR(KLAVAL-1+I).LT.0.0D0) THEN
         WRITE(6,*) ' SQRTMT : Negative eigenvalue ', SCR(KLAVAL-1+I)
         WRITE(6,*) ' SQRTMT : I will STOP '
         Call Abend2(       ' SQRTMT : Negative eigenvalue ' )
       END IF
      END DO
*
      DO 100 I = 1,NDIM
        SCR(KLAVAL-1+I) = SQRT(SCR(KLAVAL-1+I))
  100 CONTINUE
C     XDIAXT(XDX,X,DIA,NDIM,SCR)
      CALL XDIAXT(ASQRT,SCR(KLAVEC),SCR(KLAVAL),NDIM,SCR(KLFREE))
*
      IF(ITASK .EQ. 2 ) THEN
        DO 200 I = 1,NDIM
          IF(SCR(KLAVAL-1+I) .GT. 1.0D-13 ) then
            SCR(KLAVAL-1+I) = 1.0D0/SCR(KLAVAL-1+I)
          ELSE
            SCR(KLAVAL-1+I) = SCR(KLAVAL-1+I)
          END IF
  200   CONTINUE
        CALL XDIAXT(AMSQRT,SCR(KLAVEC),SCR(KLAVAL),NDIM,SCR(KLFREE))
      END IF
*
      IF( NTEST .GE. 1 ) THEN
        WRITE(6,*) ' Info from SQRTMT '
        WRITE(6,*) ' ================='
        WRITE(6,*) ' Input matrix to SQRTMT '
        CALL WRTMAT(A,NDIM,NDIM,NDIM,NDIM)
        WRITE(6,*) ' Square root of matrix '
        CALL WRTMAT(ASQRT,NDIM,NDIM,NDIM,NDIM)
        IF(ITASK .EQ. 2 ) THEN
          WRITE(6,*) ' Inverse square root of matrix '
          CALL WRTMAT(AMSQRT,NDIM,NDIM,NDIM,NDIM)
        END IF
      END IF
*
      RETURN
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
*  Dummy routine for normal compilations
*
      subroutine stdfmt(char_x,string)
      CHARACTER*72 CHAR_X
      CHARACTER*12 STRING
      return
      end
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
*  Dummy routine for normal compilations
*
      subroutine stka
      return
      end
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
*  Dummy routine for normal compilations
*
      subroutine strnln
      return
      end
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
*
      SUBROUTINE TRIPAK_BLKM(AUTPAK,APAK,IWAY,LBLOCK,NBLOCK)
*
* Switch between packed and unpacked form of a blocked matrix
*
* IWAY = 1 => Unpacked to packed
* IWAY = 2 => Packed to unpacked
*
* Jeppe Olsen, February 1, 1998 (Moensted Kalkgrubber )
*
      IMPLICIT REAL*8(A-H,O-Z)
*. Input/output
      DIMENSION AUTPAK(*),APAK(*)
*. Input
      DIMENSION LBLOCK(NBLOCK)
*
      DO IBLOCK = 1, NBLOCK
        IF(IBLOCK.EQ.1) THEN
          IOFFU = 1
          IOFFP = 1
        ELSE
          IOFFU = IOFFU + LBLOCK(IBLOCK-1)**2
          IOFFP = IOFFP + LBLOCK(IBLOCK-1)*(LBLOCK(IBLOCK-1)+1)/2
        END IF
        L = LBLOCK(IBLOCK)
        SIGNTP = 1.0
        CALL TRIPAK(AUTPAK(IOFFU),APAK(IOFFP),IWAY,L,L,SIGNTP)
C            TRIPAK(AUTPAK,APAK,IWAY,MATDIM,NDIM
      END DO
*
      NTEST = 00
      IF(NTEST.GE.100) THEN
        WRITE(6,*) ' Output from TRIPAK_BLKM'
        WRITE(6,*)
        WRITE(6,*) ' Unpacked matrix'
        WRITE(6,*) ' ==============='
        CALL APRBLM2(AUTPAK,LBLOCK,LBLOCK,NBLOCK,0)
C            APRBLM2(A,LROW,LCOL,NBLK,ISYM)
        WRITE(6,*) ' Packed matrix '
        WRITE(6,*) ' =============='
        CALL APRBLM2(  APAK,LBLOCK,LBLOCK,NBLOCK,1)
      END IF
*
      RETURN
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      SUBROUTINE TRIPK2(AUTPAK,APAK,IWAY,MATDIM,NDIM,SIGN)
C
C
C.. REFORMATING BETWEEN LOWER TRIANGULAR PACKING
C   AND FULL MATRIX FORM FOR A SYMMETRIC OR ANTI SYMMETRIC MATRIX
C
C   IWAY = 1 : FULL TO PACKED
C              LOWER HALF OF AUTPAK IS STORED IN APAK
C   IWAY = 2 : PACKED TO FULL FORM
C              APAK STORED IN LOWER HALF
C               SIGN * APAK TRANSPOSED IS STORED IN UPPPER PART
C.. NOTE : COLUMN WISE STORAGE SCHEME IS USED FOR PACKED BLOCKS
      IMPLICIT REAL*8(A-H,O-Z)
      DIMENSION AUTPAK(MATDIM,MATDIM),APAK(*)
C
      IF( IWAY .EQ. 1 ) THEN
        IJ = 0
        DO 100 J = 1,NDIM
          DO 50  I = J , NDIM
           APAK(IJ+I) = AUTPAK(I,J)
   50     CONTINUE
          IJ = IJ +NDIM-J
  100   CONTINUE
      END IF
C
      IF( IWAY .EQ. 2 ) THEN
        IJ = 0
        DO 200 J = 1,NDIM
          DO 150  I = J,NDIM
           AUTPAK(J,I) = SIGN*APAK(IJ+I)
           AUTPAK(I,J) = APAK(IJ+I)
  150     CONTINUE
          IJ = IJ + NDIM-J
  200   CONTINUE
      END IF
C
      NTEST = 0
      IF( NTEST .NE. 0 ) THEN
        WRITE(6,*) ' AUTPAK AND APAK FROM TRIPK2 '
        CALL WRTMAT(AUTPAK,NDIM,MATDIM,NDIM,MATDIM)
        CALL PRSM2(APAK,NDIM)
      END IF
C
      RETURN
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      SUBROUTINE TRNMAT(A,X,SCRA,NDIM,MATDIM)
C
C TRANSFORM MATRIX A : X(TRANS)*A*X
C A IS OVERWRITTREN BY TRANSFORMED A
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION A(MATDIM,1),X(MATDIM,1),
     +          SCRA(MATDIM,1)
C
C
      NTEST=0
C
      IF(NTEST.GE.3) THEN
       WRITE(6,1020)
 1020  FORMAT(/' *** OUTPUT FROM TRANMAT')
       WRITE(6,1030)
 1030  FORMAT(/' A- AND X-MATRIX')
       CALL WRTMAT(A,NDIM,NDIM,MATDIM,MATDIM)
       CALL WRTMAT(X,NDIM,NDIM,MATDIM,MATDIM)
      END IF
C
C A*X
      DO 1000 I=1,NDIM
       DO 900 J=1,NDIM
       AX=0.0D0
        DO 800 K=1,NDIM
         AX=AX+A(I,K)*X(K,J)
  800   CONTINUE
        SCRA(I,J)=AX
  900  CONTINUE
 1000 CONTINUE
C
      IF(NTEST.GE.2) THEN
       WRITE(6,1040)
 1040  FORMAT(/' AX MATRIX')
       CALL WRTMAT(SCRA,NDIM,NDIM,MATDIM,MATDIM)
      END IF
C
C X(TRANS)*(A*X)
      DO 600 I=1,NDIM
       DO 500 J=1,NDIM
        XAX=0.0D0
        DO 400 K=1,NDIM
         XAX=XAX+X(K,I)*SCRA(K,J)
  400   CONTINUE
        A(I,J)=XAX
  500  CONTINUE
  600 CONTINUE
C
      IF(NTEST.GE.2) THEN
       WRITE(6,1010)
 1010  FORMAT(/' TRANSFORMED MATRIX')
       CALL WRTMAT(A,NDIM,NDIM,MATDIM,MATDIM)
      END IF
C
      RETURN
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
       SUBROUTINE UNPCPC(IRC,IR,NR,IC)
*
       IMPLICIT DOUBLE PRECISION (A-H,O-Z)
*
* A compound index IRC is given for a given element in
* a column packed lower half of a matrix with NR rows.
*
* Find the corrsponding row and column numbers, IR, IC
*
* The relation to be fulfilled is
* IRC = (IC-1)*NR+IR -IC*(IC-1)/2
*
*. Start by solving equation assuming IR = IC
* the corresponding second equation  is
* -XC**2/2 + XC(NR+1.5) -(NR +IRC)
*
* Well according to Mister Bechmann
      A = -0.5D0
      B = FLOAT(NR) + 1.5D0
      C = -FLOAT(NR + IRC)
      XC = -B/(2.0D0*A)
     &   + 1.0D0/(2.0D0*A)* SQRT( B ** 2 - 4.0D0*A*C)
*. Round down to get column number
      IC = XC
*. Row number
      IR = IRC - (IC-1)*NR + IC*(IC-1)/2
*. Check
      IF(IC.GT.IR  .OR. IR.GT.NR .OR. IR .LE. 0 ) THEN
        WRITE(6,*) ' Dear Sir '
        WRITE(6,*) ' I am a subroutine called UNPCPC '
        WRITE(6,*) ' trying to do my best, but my programmer '
        WRITE(6,*) ' ( Jeppe, if you know him ) '
        WRITE(6,*) ' has left me with some problems '
        WRITE(6,*) ' So I quit in a microsecond or two '
        WRITE(6,*)
        WRITE(6,*) ' IRC IR IC NR ', IRC,IR,IC,NR
        Call Abend2( 'UNPCPC ' )
      END IF
*
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      SUBROUTINE WRITVE(VEC,NDIM)
      DOUBLE PRECISION  VEC
      DIMENSION VEC(1   )
C
      WRITE(6,1010) (VEC(I),I=1,NDIM)
 1010 FORMAT(/2X,4(2X,E15.8),/,(3X,4(2X,E15.8)))
      RETURN
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      Subroutine xquit(rc)
      Integer rc

      Open(66,File='returncode',Form='Formatted',Status='unknown')
      Write(66,*) rc
      Close(66)
      Stop
      End
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      SUBROUTINE XUFLOW
      RETURN
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
      SUBROUTINE ZERO_OFFDIAG(A,NDIM,IPACK)
*
* Zero off-diagonal elements in matrix A
*
* Jeppe Olsen, Oct 1997
*
* IF IPACK.NE.0, the matrix is assumed packed (inner loop over columns)
*
      IMPLICIT REAL*8 (A-H,O-Z)
      DIMENSION A(*)
*
      IF(IPACK.EQ.0) THEN
        DO I = 1, NDIM
          DO J = 1, NDIM
            IF(I.NE.J) THEN
              IJ = (J-1)*NDIM+I
              A(IJ) = 0.0D0
            END IF
          END DO
        END DO
      ELSE
        DO I = 1, NDIM
          DO J = 1, I-1
            IJ = I*(I-1)/2 + J
            A(IJ) = 0.0D0
          END DO
        END DO
      END IF
*
      RETURN
      END
***********************************************************************
*                                                                     *
* LUCITA, by Jeppe Olsen, DIRAC adaptation by Timo Fleig              *
*                                                                     *
***********************************************************************
* Version of Oct 21
      SUBROUTINE ZERO_OFFDIAG_BLM(A,NBLOCK,LBLOCK,IPACK)
*
* Zero off-diagonal elements in a block-diagonal matrix
* if IPACK .ne. 0, the matrix is packed (inner loop over columns)
*
* Jeppe Olsen, October 1997
*
      IMPLICIT REAL*8(A-H,O-Z)
      DIMENSION A(*),LBLOCK(NBLOCK)
*
      DO IBLOCK = 1, NBLOCK
       IF(IBLOCK.EQ.1) THEN
         IOFF = 1
       ELSE
         LPREV = LBLOCK(IBLOCK-1)
         IF(IPACK.EQ.0) THEN
           IOFF = IOFF + LPREV*(LPREV+1)/2
         ELSE
           IOFF = IOFF + LPREV*LPREV
         END IF
       END IF
       L = LBLOCK(IBLOCK)
       CALL ZERO_OFFDIAG(A(IOFF),L,IPACK)
      END DO
*
      NTEST = 100
      IF(NTEST.GE.100) THEN
        WRITE(6,*) ' Output matrix from ZERO_OFFDIAG_BLM'
        CALL APRBLM2(A,LBLOCK,LBLOCK,NBLOCK,IPACK)
C       CALL APRBLM2(WORK(KFOCK),NTOOBS,NTOOBS,NSMOB,ISM)
      END IF
*
      RETURN
      END
