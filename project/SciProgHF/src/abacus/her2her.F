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

C
C
C  /* Deck hr2drv */
      SUBROUTINE HR2DRV(HERINT,INDHER,COOR12,COOR34,EXP12,EXP34,FAC12,
     &                  FAC34,NTUV,WORK,LWORK,JMAX,MAXDER,NUABCD,IPQ0X,
     &                  IPQ0Y,IPQ0Z,NOINT,ONECEN,NUC1,NUC2,NUC12,NUC3,
     &                  NUC4,NUC34,THRESH,IPRINT,SIGNT,IODDHR)
C
C     T. Helgaker, Sep. 91
C
C     gnrinf.h needed for PANAS correction factor
C
#include "implicit.h"
#include "priunit.h"
#include "maxaqn.h"
      LOGICAL NOINT, ONECEN
      DIMENSION HERINT(NUABCD,NTUV), INDHER(*), IODDHR(*),
     &          COOR12(*), COOR34(*), EXP12(*), EXP34(*), FAC12(*),
     &          FAC34(*), SIGNT(*), WORK(LWORK)
#ifdef PRG_DIRAC
#include "dcbgen.h"
#else
#include "gnrinf.h"
#endif
#include "twosta.h"
      CALL QENTER('HR2DRV')
#include "memint.h"
      LRJ000 = (JMAX + 1)*NUABCD
      CALL MEMGET('REAL',KRJ000,LRJ000,WORK,KFREE,LFREE)
      CALL MEMGET('REAL',KPQX  ,NUABCD,WORK,KFREE,LFREE)
      CALL MEMGET('REAL',KPQY  ,NUABCD,WORK,KFREE,LFREE)
      CALL MEMGET('REAL',KPQZ  ,NUABCD,WORK,KFREE,LFREE)
      MWRJ00 = MAX(MWRJ00,LRJ000)
      LWTOT  = LWTOT + KFREE - 1
      MWTOT  = MAX(MWTOT,LWTOT)
      CALL HR2DR1(HERINT,INDHER,COOR12,COOR34,EXP12,EXP34,FAC12,FAC34,
     &            WORK(KRJ000),WORK(KPQX),WORK(KPQY),WORK(KPQZ),
     &            WORK(KFREE),LFREE,NTUV,JMAX,MAXDER,NUABCD,IPQ0X,IPQ0Y,
     &            IPQ0Z,NOINT,ONECEN,NUC1,NUC2,NUC12,NUC3,NUC4,NUC34,
     &            THRESH,IPRINT,SIGNT,IODDHR,PANAS)
      LWTOT  = LWTOT - KFREE + 1
      CALL MEMREL('HR2DRV',WORK,KWORK,KWORK,KFREE,LFREE)
      CALL QEXIT('HR2DRV')
      RETURN
      END
C  /* Deck hr2dr1 */
      SUBROUTINE HR2DR1(HERINT,INDHER,COOR12,COOR34,EXP12,EXP34,FAC12,
     &                  FAC34,RJ000,PQX,PQY,PQZ,WORK,LWORK,NTUV,JMAX,
     &                  MAXDER,NUABCD,IPQ0X,IPQ0Y,IPQ0Z,NOINT,ONECEN,
     &                  NUC1,NUC2,NUC12,NUC3,NUC4,NUC34,THRESH,IPRINT,
     &                  SIGNT,IODDHR,PANAS)
#include "implicit.h"
#include "priunit.h"
#include "maxaqn.h"
      LOGICAL NOINT, ONECEN
#include "twosta.h"
      DIMENSION HERINT(NUABCD,NTUV), INDHER(*), IODDHR(*),
     &          RJ000(NUABCD,0:JMAX), WORK(LWORK),
     &          PQX(NUABCD), PQY(NUABCD), PQZ(NUABCD),
     &          COOR12(*), COOR34(*), EXP12(*), EXP34(*), FAC12(*),
     &          FAC34(*), SIGNT(*)
C
C     Incomplete gamma function
C     =========================
C
      IF (TKTIME) TIMSTR = SECOND()
      CALL R000(RJ000,COOR12,COOR34,EXP12,EXP34,FAC12,FAC34,PQX,PQY,PQZ,
     &          JMAX,NOINT,NUABCD,NUC1,NUC2,NUC12,NUC3,NUC4,NUC34,
     &          THRESH,ONECEN,IPRINT,IPQ0X,IPQ0Y,IPQ0Z,SIGNT,PANAS,
     &          WORK,LWORK)
      IF (TKTIME) THEN
         TIMEND = SECOND()
         TIME = TIMEND - TIMSTR
         TR000X(JMAX) = TR000X(JMAX) + TIME
         TR000 = TR000 + TIME
         TIMSTR = TIMEND
      END IF
C
C     Hermite integrals
C     =================
C
      IF (.NOT.NOINT) THEN
C
C        Calculate integrals
C
         CALL HERI(HERINT,WORK,LWORK,RJ000,PQX,PQY,PQZ,INDHER,JMAX,
     &             MAXDER,NUABCD,NTUV,IPQ0X,IPQ0Y,IPQ0Z,IODDHR,IPRINT)
         IF (TKTIME) THEN
            TIMEND = SECOND()
            TIME = TIMEND - TIMSTR
            THERIX(JMAX) = THERIX(JMAX) + TIME
            THERI = THERI + TIME
            TIMSTR = TIMEND
         END IF
      END IF
      RETURN
      END
C  /* Deck r000 */
      SUBROUTINE R000(RJ000,COOR12,COOR34,EXP12,EXP34,FAC12,FAC34,PQX,
     &                PQY,PQZ,JMAX,NOINT,NUABCD,NUC1,NUC2,NUC12,NUC3,
     &                NUC4,NUC34,THRESH,ONECEN,IPRINT,IPQ0X,IPQ0Y,IPQ0Z,
     &                SIGNT,PANAS,WORK,LWORK)
C
C     TUH 84
C
#include "implicit.h"
#include "priunit.h"
#include "maxaqn.h"
#include "twosta.h"
      LOGICAL ONECEN, NOINT
      DIMENSION RJ000(*), PQX(*), PQY(*), PQZ(*), COOR12(*), COOR34(*),
     &          EXP12 (*), EXP34(*), FAC12 (*), FAC34(*), SIGNT(3),
     &          WORK(LWORK)
C-----------------------------------------------------------------------
      CALL QENTER('R000')
#include "memint.h"
      CALL MEMGET('REAL',KWVALU,NUABCD,WORK,KFREE,LFREE)
      CALL MEMGET('REAL',KALPHA,NUABCD,WORK,KFREE,LFREE)
      CALL MEMGET('REAL',KALPHJ,NUABCD,WORK,KFREE,LFREE)
      CALL MEMGET('INTE',KINDAD,NUABCD,WORK,KFREE,LFREE)
      LWTOT  = LWTOT + KFREE - 1
      MWTOT  = MAX(MWTOT,LWTOT)
      CALL R0001(RJ000,COOR12,COOR34,EXP12,EXP34,FAC12,FAC34,PQX,PQY,
     &           PQZ,JMAX,NOINT,NUABCD,NUC1,NUC2,NUC12,NUC3,NUC4,NUC34,
     &           THRESH,ONECEN,IPRINT,IPQ0X,IPQ0Y,IPQ0Z,SIGNT,
     &           WORK(KWVALU),WORK(KALPHj),WORK(KALPHa),WORK(KINDAD),
     &           PANAS,WORK(KFREE),LFREE)
      LWTOT  = LWTOT - KFREE + 1
      CALL MEMREL('R000',WORK,KWORK,KWORK,KFREE,LFREE)
      CALL QEXIT('R000')
      RETURN
      END
C  /* Deck r0001 */
      SUBROUTINE R0001(RJ000,COOR12,COOR34,EXP12,EXP34,FAC12,FAC34,PQX,
     &                PQY,PQZ,JMAX,NOINT,NUABCD,NUC1,NUC2,NUC12,NUC3,
     &                NUC4,NUC34,THRESH,ONECEN,IPRINT,IPQ0X,IPQ0Y,IPQ0Z,
     &                SIGNT,WVALU,TALPHA,SCLFAC,INDADR,PANAS,WORK,LWORK)
C
C     TUH 84
C
#include "implicit.h"
#include "priunit.h"
#include "maxaqn.h"
#include "aovec.h"
      PARAMETER (D0 = 0.D0, D1 = 1.D0, D2 = 2.D0)
      LOGICAL ONECEN, NOINT
      DIMENSION RJ000(NUABCD,0:JMAX), WORK(LWORK),
     &          PQX(NUABCD), PQY(NUABCD), PQZ(NUABCD),
     &          COOR12(NUC1*NUC2,3), COOR34(NUC3*NUC4,3),
     &          EXP12 (*), EXP34(*), FAC12 (*), FAC34(*), SIGNT(3),
     &          WVALU(NUABCD), TALPHA(NUABCD), INDADR(NUABCD),
     &          SCLFAC(NUABCD)
#include "dcbham.h"
#include "twosta.h"
#include "subdir.h"
      CALL QENTER('R0001')
#include "memint.h"
C-----------------------------------------------------------------------
C
C     *****************
C     ***** RJ000 *****
C     *****************
C
C
C     Special case: One-center Integrals
C     ==================================
C
C     Note: There should be no testing for small integrals since
C     this may in the case of one-center integrals introduce
C     numerical instabilities for large exponents.
C
      NOINT = .FALSE.
      IF (ONECEN) THEN
         IODS = 0
         CALL DZERO(PQX,NUABCD)
         CALL DZERO(PQY,NUABCD)
         CALL DZERO(PQZ,NUABCD)
         IPQ0X = 1
         IPQ0Y = 1
         IPQ0Z = 1
         DO 100 IOD12 = 1, NUC12
            EXPP   = EXP12(IOD12)
            FAC12I = FAC12(IOD12)
            IF (HFXMU .NE. D0) THEN
               DO IOD34 = 1, NUC34
                  IODS   = IODS + 1
                  EXPQ   = EXP34(IOD34)
                  EXPPQ  = EXPP + EXPQ
                  EXPPQI = D1/(EXPP + EXPQ)
                  FACTOR = FAC12I*FAC34(IOD34)*SQRT(EXPPQI)
                  ALPHA  = EXPP*EXPQ*EXPPQI
                  BETA   = HFXMU**2/(ALPHA + HFXMU**2)
                  TALPHA(IODS) = - D2*ALPHA*BETA
                  RJ000(IODS,0) = SQRT(BETA)*FACTOR
               END DO
            ELSEIF (PANAS .EQ. D0) THEN
               DO 110 IOD34 = 1, NUC34
                  IODS   = IODS + 1
                  EXPQ   = EXP34(IOD34)
                  EXPPQ  = EXPP + EXPQ
                  EXPPQI = D1/(EXPP + EXPQ)
                  FACTOR = FAC12I*FAC34(IOD34)*SQRT(EXPPQI)
                  TALPHA(IODS) = - D2*EXPP*EXPQ*EXPPQI
                  RJ000(IODS,0) = FACTOR
 110           CONTINUE
            ELSE
               DO 111 IOD34 = 1, NUC34
                  IODS   = IODS + 1
                  EXPQ   = EXP34(IOD34)
                  EXPPQ  = EXPP + EXPQ
                  EXPMOD = EXPPQ/D2
C.................this is eq. (48) for (chi)**2 of Panas&Snis, 
C.................Theor. Chem. Acc. 97(1997) 232
                  EXPPQP = EXPMOD + SQRT(EXPMOD**2 + EXPP*EXPQ*PANAS)
                  FACTOR = FAC12I*FAC34(IOD34)*SQRT(D1/EXPPQP)
C.................this is -2tau, where tau is from eq. (46)
                  TALPHA(IODS) = - D2*EXPP*EXPQ/EXPPQP
                  RJ000(IODS,0) = FACTOR
 111           CONTINUE
            END IF
  100    CONTINUE
         IF (JMAX .GT. 0) THEN
            CALL DCOPY(NUABCD,TALPHA,1,SCLFAC,1)
            DO 200 J = 1, JMAX
               FAC = D1/dble(2*J + 1)
               DO 210 I = 1, NUABCD
                  RJ000(I,J) = FAC*SCLFAC(I)*RJ000(I,0)
                  SCLFAC(I) = TALPHA(I)*SCLFAC(I)
  210          CONTINUE
  200       CONTINUE
         END IF
C
C     General case: Multicenter Integrals
C     ===================================
C
      ELSE
         IF (.NOT.DPATH1) THEN
            SGN12X = - SIGNT(1)
            SGN12Y = - SIGNT(2)
            SGN12Z = - SIGNT(3)
            SGN34X = - D1
            SGN34Y = - D1
            SGN34Z = - D1
         ELSE
            SGN12X = D1
            SGN12Y = D1
            SGN12Z = D1
            SGN34X = SIGNT(1)
            SGN34Y = SIGNT(2)
            SGN34Z = SIGNT(3)
         END IF
C
         IODS  = 0
         NODS  = 0
         DO 300 IOD12 = 1, NUC12
            EXPP   = EXP12(IOD12)
            FAC12I = FAC12(IOD12)
            PX     = SGN12X*COOR12(IOD12,1)
            PY     = SGN12Y*COOR12(IOD12,2)
            PZ     = SGN12Z*COOR12(IOD12,3)
            IF (HFXMU .NE. D0) THEN
               DO IOD34 = 1, NUC34
                  IODS = IODS + 1
                  EXPQ   = EXP34(IOD34)
                  EXPPQI = D1/(EXPP + EXPQ)
                  FACTOR = FAC12I*FAC34(IOD34)*SQRT(EXPPQI)
                  ALPHA = EXPP*EXPQ*EXPPQI
                  BETA = HFXMU**2/(ALPHA + HFXMU**2)
                  SCLFAC(IODS) = SQRT(BETA)*FACTOR
                  NODS = NODS + 1
                  TALPHA(IODS) = - D2*ALPHA*BETA
                  PQXI = PX - SGN34X*COOR34(IOD34,1)
                  PQYI = PY - SGN34Y*COOR34(IOD34,2)
                  PQZI = PZ - SGN34Z*COOR34(IOD34,3)
                  PQX(IODS) = PQXI
                  PQY(IODS) = PQYI
                  PQZ(IODS) = PQZI
                  WVALU(NODS)=ALPHA*BETA*
     &               (PQXI*PQXI+PQYI*PQYI+PQZI*PQZI)
                  INDADR(NODS) = IODS
               END DO
            ELSEIF (PANAS .EQ. D0) THEN
               DO 310 IOD34 = 1, NUC34
                  IODS = IODS + 1
                  EXPQ   = EXP34(IOD34)
                  EXPPQI = D1/(EXPP + EXPQ)
                  FACTOR = FAC12I*FAC34(IOD34)*SQRT(EXPPQI)
                  SCLFAC(IODS) = FACTOR
                  NODS = NODS + 1
                  ALPHA = EXPP*EXPQ*EXPPQI
                  TALPHA(IODS) = - D2*ALPHA
                  PQXI = PX - SGN34X*COOR34(IOD34,1)
                  PQYI = PY - SGN34Y*COOR34(IOD34,2)
                  PQZI = PZ - SGN34Z*COOR34(IOD34,3)
                  PQX(IODS) = PQXI
                  PQY(IODS) = PQYI
                  PQZ(IODS) = PQZI
                  WVALU(NODS) = ALPHA*(PQXI*PQXI+PQYI*PQYI+PQZI*PQZI)
                  INDADR(NODS) = IODS
 310           CONTINUE
            ELSE
               DO 311 IOD34 = 1, NUC34
                  IODS = IODS + 1
                  EXPQ   = EXP34(IOD34)
                  EXPPQ  = EXPP + EXPQ
                  EXPMOD = EXPPQ/D2
                  EXPPQP = EXPMOD + SQRT(EXPMOD**2 + EXPP*EXPQ*PANAS)
                  FACTOR = FAC12I*FAC34(IOD34)*SQRT(D1/EXPPQP)
                  SCLFAC(IODS) = FACTOR
                  NODS = NODS + 1
                  ALPHA = EXPP*EXPQ/EXPPQP
                  TALPHA(IODS) = - D2*ALPHA
                  PQXI = PX - SGN34X*COOR34(IOD34,1)
                  PQYI = PY - SGN34Y*COOR34(IOD34,2)
                  PQZI = PZ - SGN34Z*COOR34(IOD34,3)
                  PQX(IODS) = PQXI
                  PQY(IODS) = PQYI
                  PQZ(IODS) = PQZI
                  WVALU(NODS) = ALPHA*(PQXI*PQXI+PQYI*PQYI+PQZI*PQZI)
                  INDADR(NODS) = IODS
 311           CONTINUE
            END IF
  300    CONTINUE
         IF (.NOT.NOINT) THEN
            IPQ0X = 1
            IPQ0Y = 1
            IPQ0Z = 1
            IF (DASUM(NUABCD,PQX,1) .GT. THRESH) IPQ0X = 0
            IF (DASUM(NUABCD,PQY,1) .GT. THRESH) IPQ0Y = 0
            IF (DASUM(NUABCD,PQZ,1) .GT. THRESH) IPQ0Z = 0
C
            CALL DZERO(RJ000(1,0),(JMAX+1)*NUABCD)
C
C           Calculate gamma function
C           ========================
C
C           Allocations
C
            CALL MEMGET('INTE',KINDAD,3*NODS         ,WORK,KFREE,LFREE)
            CALL MEMGET('REAL',KWVALS,3*NODS         ,WORK,KFREE,LFREE)
            CALL MEMGET('REAL',KFJW  ,NODS*(JMAX + 1),WORK,KFREE,LFREE)
            CALL MEMGET('REAL',KREXPW,NODS           ,WORK,KFREE,LFREE)
            LWTOT  = LWTOT + KFREE - 1
            MWTOT  = MAX(MWTOT,LWTOT)
            CALL GETGAM(NODS,INDADR,WVALU,RJ000,JMAX,NUABCD,WORK(KFJW),
     &                  WORK(KINDAD),WORK(KWVALS),WORK(KREXPW),IPRINT)
            LWTOT  = LWTOT - KFREE + 1
            CALL MEMREL('R0001',WORK,KWORK,KWORK,KFREE,LFREE)
C
C           Scale gamma function
C
            DO 400 J = 0, JMAX
               DO 410 I = 1, NUABCD
                  RJ000(I,J) = SCLFAC(I)*RJ000(I,J)
                  SCLFAC(I) = TALPHA(I)*SCLFAC(I)
  410          CONTINUE
  400       CONTINUE
         END IF
      END IF
C
C     *************************
C     ***** PRINT SECTION *****
C     *************************
C
      IF (IPRINT .GT. 10) THEN
         WRITE (LUPRI, 1000)
         WRITE (LUPRI, 1010) JMAX
         WRITE (LUPRI, 1020) NUC12, NUC34
         WRITE (LUPRI, 1030) THRESH
         WRITE (LUPRI, 1040) ONECEN
         WRITE (LUPRI, 1045) NOINT
         WRITE (LUPRI, 1050) NUABCD
         IF (IPRINT .GT. 20) THEN
            WRITE (LUPRI, 1100)
            ISTART = 0
            DO 500 J = 0, JMAX
               WRITE (LUPRI, 1110) J
               IADR = 0
               DO 510 I = 1, NUC12
                  WRITE (LUPRI, 1120) I
                  WRITE (LUPRI, 1130) (RJ000(IADR + K,J), K = 1, NUC34)
                  IADR = IADR + NUC34
  510          CONTINUE
  500       CONTINUE
         END IF
      END IF
 1000 FORMAT (//,' ********** SUBROUTINE R000 **********')
 1010 FORMAT (//,'  JMAX    ',I7)
 1020 FORMAT (   '  NUC     ',2I7)
 1030 FORMAT (   '  THRESH  ',1P,D12.4)
 1040 FORMAT (   '  ONECEN  ',L7)
 1045 FORMAT (   '  NOINT   ',L7)
 1050 FORMAT (   '  NUABCD  ',I7)
 1100 FORMAT(//,' ***** RJ000 - INTEGRALS *****')
 1110 FORMAT( /,'  J     ',I7)
 1120 FORMAT( /,'  NUC12 ',I7,/)
 1130 FORMAT(1P,6D12.4)
      CALL QEXIT('R0001')
      RETURN
      END
C  /* Deck getgam */
      SUBROUTINE GETGAM(NODS,INDADR,WVALU,RJ000,JMAX,NUABCD,FJWS,INDADS,
     &                  WVALS,REXPW,IPRINT)
#include "implicit.h"
#include "priunit.h"
#include "maxaqn.h"
#include "pi.h"
      PARAMETER (HALF = 0.5D0)
      PARAMETER (D1 = 1.D0, D10 = 10.D0)
      PARAMETER (D2 = 2.D0, D4 = 4.D0, D6 = 6.D0, D12 = 12.D0,
     &           D24 = 24.D0, D120 = 120.D0, D720 = 720.D0, TENTH =.1D0)
      PARAMETER (COEF2 = D1/D2,  COEF3 = - D1/D6, COEF4 = D1/D24,
     &           COEF5 = - D1/D120, COEF6 = D1/D720)
      PARAMETER (GFAC0 =  D2*0.4999489092 D0,
     &           GFAC1 = -D2*0.2473631686 D0,
     &           GFAC2 =  D2*0.321180909  D0,
     &           GFAC3 = -D2*0.3811559346 D0)
      PARAMETER (SQRPIH = 0.88622 69254 52758 D00)
      PARAMETER (PID4 = PI/D4, PID4I = D4/PI)
#include "gamcom.h"
      DIMENSION FJWS(NODS,0:JMAX), INDADR(*),
     &          WVALU(*), RJ000(NUABCD,0:JMAX), INDADS(NODS,3),
     &          WVALS(NODS,3), REXPW(NODS)
C-----------------------------------------------------------------------
C
      NODS1 = 0
      NODS2 = 0
      NODS3 = 0
      D2JP36 = dble(2*JMAX + 36)
      DO 100 I = 1, NODS
         WVAL = WVALU(I)
         IF (WVAL .LT. D12) THEN
            NODS1 = NODS1 + 1
            INDADS(NODS1,1) = INDADR(I)
            WVALS(NODS1,1)  = WVAL
         ELSE IF (WVAL .LE. D2JP36) THEN
            NODS2 = NODS2 + 1
            INDADS(NODS2,2) = INDADR(I)
            WVALS(NODS2,2)  = WVAL
         ELSE
            NODS3 = NODS3 + 1
            INDADS(NODS3,3) = INDADR(I)
            WVALS(NODS3,3)  = WVAL
         END IF
  100 CONTINUE
C
C     WVAL < 12
C
      IF (NODS1 .GT. 0) THEN
         ISTRT0 = 1 + 121*JMAX
         DO 200 I = 1, NODS1
            WVAL = WVALS(I,1)
            IPNT = NINT(D10*WVAL)
            WDIF = WVAL - TENTH*dble(IPNT)
            ISTART = ISTRT0 + IPNT
            FJWS(I,JMAX) = (((((COEF6*TABFJW(ISTART + 726)*WDIF
     &                         + COEF5*TABFJW(ISTART + 605))*WDIF
     &                         + COEF4*TABFJW(ISTART + 484))*WDIF
     &                         + COEF3*TABFJW(ISTART + 363))*WDIF
     &                         + COEF2*TABFJW(ISTART + 242))*WDIF
     &                         - TABFJW(ISTART + 121))*WDIF
     &                         + TABFJW(ISTART)
  200    CONTINUE
         IF (JMAX .GT. 0) THEN
            DO 300 I = 1, NODS1
               REXPW(I) = HALF*EXP(-WVALS(I,1))
  300       CONTINUE
            DO 310 J = JMAX - 1, 0, -1
               FCT = D2/dble(2*J + 1)
               DO 320 I = 1, NODS1
                  FJWS(I,J) = FCT*(WVALS(I,1)*FJWS(I,J+1) + REXPW(I))
  320          CONTINUE
  310       CONTINUE
            DO 330 J = 1, JMAX
               DO 340 I = 1, NODS1
                  RJ000(INDADS(I,1),J) = FJWS(I,J)
  340          CONTINUE
  330       CONTINUE
         END IF
         DO 350 I = 1, NODS1
            RJ000(INDADS(I,1),0) = FJWS(I,0)
  350    CONTINUE
      END IF
C
C     Near asymptotic region
C
      IF (NODS2 .GT. 0) THEN
         DO 400 I = 1, NODS2
            WVAL       = WVALS(I,2)
            REXPW(I)   = HALF*EXP(-WVAL)
            WVALS(I,2) = D1/WVAL
  400    CONTINUE
         DO 410 I = 1, NODS2
            RWVAL = WVALS(I,2)
            GVAL = GFAC0 + RWVAL*(GFAC1 + RWVAL*(GFAC2 + RWVAL*GFAC3))
            FJWS(I,0) = SQRPIH*SQRT(RWVAL) - REXPW(I)*GVAL*RWVAL
  410    CONTINUE
         DO 420 I = 1, NODS2
            RJ000(INDADS(I,2),0) = FJWS(I,0)
  420    CONTINUE
         DO 430 J = 1, JMAX
            FCT = dble(J) - HALF
            DO 440 I = 1, NODS2
               FJWS(I,J) = (FCT*FJWS(I,J-1) - REXPW(I))*WVALS(I,2)
  440       CONTINUE
            DO 450 I = 1, NODS2
               RJ000(INDADS(I,2),J) = FJWS(I,J)
  450       CONTINUE
  430    CONTINUE
      END IF
C
C     Asymptotic region
C
      IF (NODS3 .GT. 0) THEN
         DO 500 I = 1, NODS3
            WVALS(I,3) = PID4/WVALS(I,3)
  500    CONTINUE
         DO 510 I = 1, NODS3
            FJWS(I,0) = SQRT(WVALS(I,3))
  510    CONTINUE
         DO 520 I = 1, NODS3
            RJ000(INDADS(I,3),0) = FJWS(I,0)
  520    CONTINUE
         DO 530 J = 1, JMAX
            FACTOR = PID4I*(dble(J) - HALF)
            DO 540 I = 1, NODS3
               FJWS(I,J) = FACTOR*FJWS(I,J-1)*WVALS(I,3)
  540       CONTINUE
            DO 550 I = 1, NODS3
               RJ000(INDADS(I,3),J) = FJWS(I,J)
  550       CONTINUE
  530    CONTINUE
      END IF
C
      RETURN
      END
C  /* Deck heri */
      SUBROUTINE HERI(HERINT,WORK,LWORK,RJ000,PQX,PQY,PQZ,INDHER,JMAX,
     &                MAXDER,NUABCD,NTUV,IPQ0X,IPQ0Y,IPQ0Z,IODDHR,
     &                IPRINT)
C
C     tuh fall 1984
C
C     Modified Jul 28 88 to avoid multiplying zero with
C     undetermined numbers - tuh
C
C     Modified for triangular addressing March 92 - tuh
C
#include "implicit.h"
#include "priunit.h"
#include "maxaqn.h"
      INTEGER T, U, V, TUV
      DIMENSION WORK(LWORK), RJ000(NUABCD,0:JMAX), IODDHR(*),
     &          PQX(NUABCD), PQY(NUABCD), PQZ(NUABCD),
     &          INDHER(0:JTOP,0:JTOP,0:JTOP), HERINT(NUABCD,NTUV)
#include "twosta.h"
#include "hertop.h"
      CALL QENTER('HERI')
#include "memint.h"
C
C     The final R(T,U,V) integrals are arranged as follows:
C
C     R(000)
C     R(100) R(010) R(001)
C     R(200) R(110) R(101) R(020) R(011) R(002)
C     R(300) R(210) R(201) R(120) R(111) R(102) R(030) R(021) R(012)
C                                                             R(003)
C     Special case JMAX = 0
C     =====================
C
      IF (JMAX .EQ. 0) THEN
         CALL DCOPY(NUABCD,RJ000,1,HERINT,1)
      ELSE
C
C        Allocate work space
C        ===================
C
         LHRWRK = NTUV*NUABCD
         CALL MEMGET('REAL',KHRWRK,LHRWRK,WORK,KFREE,LFREE)
         MWHRSQ = MAX(MWHRSQ,LHRWRK)
         LWTOT  = LWTOT + KFREE - 1
         MWTOT  = MAX(MWTOT,LWTOT)
C
C        Recursion loop for Hermite integrals
C        ====================================
C
         IPQX = IPQ0X + 1
         IPQY = IPQ0Y + 1
         IPQZ = IPQ0Z + 1
         CALL DZERO(HERINT,NUABCD*NTUV)
         DO 200 JVAL = 1, JMAX
            IF (MOD(JMAX-JVAL,2).EQ.0) THEN
               CALL HRECUR(HERINT,WORK(KHRWRK),JVAL,RJ000,PQX,PQY,PQZ,
     &                     INDHER,JMAX,MAXDER,NUABCD,NTUV,IPQX,IPQY,
     &                     IPQZ)
            ELSE
               CALL HRECUR(WORK(KHRWRK),HERINT,JVAL,RJ000,PQX,PQY,PQZ,
     &                     INDHER,JMAX,MAXDER,NUABCD,NTUV,IPQX,IPQY,
     &                     IPQZ)
            END IF
  200    CONTINUE
         LWTOT  = LWTOT - KFREE + 1
         CALL MEMREL('HERI',WORK,KWORK,KWORK,KFREE,LFREE)
      END IF
C
C     Print section
C     =============
C
      IF (IPRINT .GE. 10) THEN
         CALL TITLER('Output from HERI','*',103)
         WRITE (LUPRI,'(2X,A,I5)') 'JMAX  ', JMAX
         WRITE (LUPRI,'(2X,A,I5)') 'NUABCD', NUABCD
         WRITE (LUPRI,'(2X,A,I5)') 'NTUV  ', NTUV
         IF (IPRINT .GE. 20) THEN
            CALL HEADER('Hermite integrals R(t,u,v)',1)
            DO 300 J = 0, JMAX
              DO 320 T = J, 0, -1
                DO 330 U = J - T, 0, -1
                  V = J - T - U
                  TUV = INDHER(T,U,V)
                  IF (IODDHR(TUV) .EQ. 0) THEN
                    WRITE (LUPRI,'(2X,3(A,I1),A,2X,5F12.8/,
     &                                                 (12X,5F12.8))')
     &              'R(',T,',',U,',',V,')', (HERINT(I,TUV),I=1,NUABCD)
                  WRITE (LUPRI,'()')
                  END IF
  330           CONTINUE
  320         CONTINUE
  300      CONTINUE
         END IF
      END IF
      CALL QEXIT('HERI')
      RETURN
      END
C  /* Deck hrecur */
      SUBROUTINE HRECUR(CUR,OLD,JVAL,RJ000,PQX,PQY,PQZ,INDHER,JMAX,
     &                  MAXDER,NUABCD,NTUV,IPQX,IPQY,IPQZ)
C
#include "implicit.h"
      INTEGER T, U, V, TUV
      LOGICAL PQXGT0, PQYGT0, PQZGT0
      DIMENSION CUR(NUABCD,NTUV), OLD(NUABCD,NTUV),
     &          INDHER(0:JTOP,0:JTOP,0:JTOP),
     &          PQX(NUABCD), PQY(NUABCD), PQZ(NUABCD),
     &          RJ000(NUABCD,0:JMAX)
#include "doxyz.h"
#include "hertop.h"
C
      PQXGT0 = IPQX .EQ. 1
      PQYGT0 = IPQY .EQ. 1
      PQZGT0 = IPQZ .EQ. 1
C
C     JVAL = 1
C     ========
C
      IF (JVAL .EQ. 1) THEN
         CALL DCOPY(NUABCD,RJ000(1,JMAX-1),1,CUR(1,1),1)
         IF (PQXGT0) THEN
            DO 110 I = 1, NUABCD
               CUR(I,2) = PQX(I)*RJ000(I,JMAX)
  110       CONTINUE
         END IF
         IF (PQYGT0) THEN
            DO 120 I = 1, NUABCD
               CUR(I,3) = PQY(I)*RJ000(I,JMAX)
  120       CONTINUE
         END IF
         IF (PQZGT0) THEN
            DO 130 I = 1, NUABCD
               CUR(I,4) = PQZ(I)*RJ000(I,JMAX)
  130       CONTINUE
         END IF
C
C     JVAL > 1
C     ========
C
      ELSE
         MAXT   = JMAX
         MAXU   = JMAX
         MAXV   = JMAX
         IF (.NOT.DOX) MAXT = JMAX - MAXDER
         IF (.NOT.DOY) MAXU = JMAX - MAXDER
         IF (.NOT.DOZ) MAXV = JMAX - MAXDER
C
C        R(0,0,0)
C
         CALL DCOPY(NUABCD,RJ000(1,JMAX-JVAL),1,CUR,1)
C
C        R(T,0,0)
C
         IF (PQXGT0) THEN
            DO 200 I = 1, NUABCD
               CUR(I,2) = PQX(I)*OLD(I,1)
  200       CONTINUE
            DO 300 T = 2, MIN(MAXT,JVAL)
               TMIN1 = dble(T - 1)
               TUV   = INDHER(T  ,0,0)
               M1T   = INDHER(T-1,0,0)
               M2T   = INDHER(T-2,0,0)
               DO 310 I = 1, NUABCD
                  CUR(I,TUV) = PQX(I)*OLD(I,M1T) + TMIN1*OLD(I,M2T)
  310          CONTINUE
  300       CONTINUE
         ELSE
            DO 400 T = 2, MIN(MAXT,JVAL), 2
               TMIN1 = dble(T - 1)
               TUV   = INDHER(T  ,0,0)
               M2T   = INDHER(T-2,0,0)
               DO 410 I = 1, NUABCD
                  CUR(I,TUV) = TMIN1*OLD(I,M2T)
  410          CONTINUE
  400       CONTINUE
         END IF
C
C        R(T,U,0)
C
         IF (PQYGT0) THEN
            DO 500 T = 0, MIN(MAXT,JVAL - 1), IPQX
               TUV = INDHER(T,1,0)
               M1U = INDHER(T,0,0)
               DO 510 I = 1, NUABCD
                  CUR(I,TUV) = PQY(I)*OLD(I,M1U)
  510          CONTINUE
  500       CONTINUE
            DO 600 U = 2, MIN(MAXU,JVAL)
               UMIN1  = dble(U - 1)
               DO 610 T = 0, MIN(MAXT,JVAL - U), IPQX
                  TUV = INDHER(T,U  ,0)
                  M1U = INDHER(T,U-1,0)
                  M2U = INDHER(T,U-2,0)
                  DO 620 I = 1, NUABCD
                     CUR(I,TUV) = PQY(I)*OLD(I,M1U) + UMIN1*OLD(I,M2U)
  620             CONTINUE
  610          CONTINUE
  600       CONTINUE
         ELSE
            DO 700 U = 2, MIN(MAXU,JVAL), 2
               UMIN1  = dble(U - 1)
               DO 710 T = 0, MIN(MAXT,JVAL - U), IPQX
                  TUV = INDHER(T,U  ,0)
                  M2U = INDHER(T,U-2,0)
                  DO 720 I = 1, NUABCD
                     CUR(I,TUV) = UMIN1*OLD(I,M2U)
  720             CONTINUE
  710          CONTINUE
  700       CONTINUE
         END IF
C
C        R(T,U,V)
C
         IF (PQZGT0) THEN
            IUMAX  = JVAL - 1
            DO 800 U = 0, MIN(MAXU,IUMAX), IPQY
               DO 810 T = 0, MIN(MAXT,IUMAX - U), IPQX
                  TUV = INDHER(T,U,1)
                  M1V = INDHER(T,U,0)
                  DO 820 I = 1, NUABCD
                     CUR(I,TUV) = PQZ(I)*OLD(I,M1V)
  820             CONTINUE
  810          CONTINUE
  800       CONTINUE
            DO 900 V = 2, MIN(MAXV,JVAL)
               VMIN1  = dble(V - 1)
               IUMAX  = JVAL - V
               DO 910 U = 0, MIN(MAXU,IUMAX), IPQY
                  DO 920 T = 0, MIN(MAXT,IUMAX - U), IPQX
                     TUV = INDHER(T,U,V  )
                     M1V = INDHER(T,U,V-1)
                     M2V = INDHER(T,U,V-2)
                     DO 930 I = 1, NUABCD
                        CUR(I,TUV) = PQZ(I)*OLD(I,M1V)+VMIN1*OLD(I,M2V)
  930                CONTINUE
  920             CONTINUE
  910          CONTINUE
  900       CONTINUE
         ELSE
            DO 1000 V = 2, MIN(MAXV,JVAL), 2
               VMIN1  = dble(V - 1)
               IUMAX  = JVAL - V
               DO 1010 U = 0, MIN(MAXU,IUMAX), IPQY
                  DO 1020 T = 0, MIN(MAXT,IUMAX - U), IPQX
                     TUV = INDHER(T,U,V  )
                     M2V = INDHER(T,U,V-2)
                     DO 1030 I = 1, NUABCD
                        CUR(I,TUV) = VMIN1*OLD(I,M2V)
 1030                CONTINUE
 1020             CONTINUE
 1010          CONTINUE
 1000       CONTINUE
         END IF
      END IF
      RETURN
      END
C  /* Deck herswp */
      SUBROUTINE HERSWP(HERINT,NTUV,NUABCD,WORK,LWORK,JMAX,NUCAB,
     &                  NUCCD,IPRINT)
C
C     TUH 87
C
#include "implicit.h"
#include "priunit.h"
      DIMENSION HERINT(NUABCD,NTUV), WORK(LWORK)
      NHRINT = NTUV*NUABCD
      IF (NHRINT .GT. LWORK) CALL STOPIT('HERSWP',' ',LWORK,NHRINT)
      ISTR10 = 1
      ISTR2  = 1
      DO 100 I = 1, NUCAB
         ISTR1 = ISTR10
         DO 200 J = 1, NUCCD
            CALL DCOPY(NTUV,HERINT(ISTR2,1),NUABCD,WORK(ISTR1),NUABCD)
            ISTR1 = ISTR1 + NUCAB
            ISTR2 = ISTR2 + 1
  200    CONTINUE
         ISTR10 = ISTR10 + 1
  100 CONTINUE
      CALL DCOPY(NHRINT,WORK,1,HERINT,1)
      IF (IPRINT .GE. 25) THEN
         CALL HEADER('OUTPUT FROM HERSWP',-1)
         DO 500 ITUV = 1, NTUV
            WRITE (LUPRI,'(/,A,I5/)') ' NR ',ITUV
            WRITE (LUPRI,'(6F12.8)') (HERINT(I,ITUV),I=1,NUABCD)
  500    CONTINUE
      END IF
      RETURN
      END
C  /* Deck r000x */
#if defined (VAR_OLDGAM)
      SUBROUTINE R000X(RJ000,COOR12,COOR34,EXP12,EXP34,FAC12,FAC34,PQX,
     &                 PQY,PQZ,JMAX,NOINT,NUABCD,NUC1,NUC2,NUC12,NUC3,
     &                 NUC4,NUC34,THRESH,ONECEN,IPRINT,IPQ0X,IPQ0Y,
     &                 IPQ0Z)
C
C     TUH 84
C
#include "implicit.h"
#include "priunit.h"
#include "maxaqn.h"
#include "aovec.h"
      PARAMETER (D0 = 0.D0, D1 = 1.D0, D2 = 2.D0)
      LOGICAL ONECEN, NOINT
      DIMENSION RJ000(NUABCD,0:JMAX),
     &          PQX(NUABCD), PQY(NUABCD), PQZ(NUABCD),
     &          COOR12(NUC1*NUC2,3), COOR34(NUC3*NUC4,3),
     &          EXP12 (NUC1*NUC2),   EXP34 (NUC3*NUC4),
     &          FAC12 (NUC1*NUC2),   FAC34 (NUC3*NUC4)
#include "gamcom.h"
#include "twosta.h"
#include "subdir.h"
      IF (.NOT.DPATH1) THEN
         SIGN   = - D1
      ELSE
         SIGN   = D1
      END IF
      JMAX0 = JMAX
      NOINT = .TRUE.
      IPQ0X = 1
      IPQ0Y = 1
      IPQ0Z = 1
C
C     *****************
C     ***** RJ000 *****
C     *****************
C
C     Special case: One-center Integrals
C     ==================================
C
      IF (ONECEN) THEN
         IODS = 0
         DO 200 IOD12 = 1, NUC12
            EXPP   = EXP12(IOD12)
            FAC12I = FAC12(IOD12)
            DO 210 IOD34 = 1, NUC34
               IODS   = IODS + 1
               EXPQ   = EXP34(IOD34)
               FAC34I = FAC34(IOD34)
               EXPPQI = EXPP + EXPQ
               FACTOR = FAC12I*FAC34I/SQRT(EXPPQI)
               IF (ABS(FACTOR) .GT. THRESH) THEN
                  NOINT = .FALSE.
                  ALPHA = EXPP*EXPQ/EXPPQI
                  PQX(IODS) = D0
                  PQY(IODS) = D0
                  PQZ(IODS) = D0
                  TALPHA = ALPHA + ALPHA
                  FJ0INV = D1
                  DO 220 I = 0, JMAX
                     RJ000(IODS,I) = FACTOR/FJ0INV
                     FACTOR = - TALPHA*FACTOR
                     FJ0INV = FJ0INV + D2
  220             CONTINUE
               ELSE
                  DO 225 I = 0 ,JMAX
                     RJ000(IODS,I) = D0
  225             CONTINUE
               END IF
  210       CONTINUE
  200    CONTINUE
C
C     General case: Multicenter Integrals
C     ===================================
C
      ELSE
         IODS = 0
         DO 300 IOD12 = 1, NUC12
            EXPP   = EXP12(IOD12)
            FAC12I = FAC12(IOD12)
            PX     = COOR12(IOD12,1)
            PY     = COOR12(IOD12,2)
            PZ     = COOR12(IOD12,3)
            DO 310 IOD34 = 1, NUC34
               IODS   = IODS + 1
               EXPQ   = EXP34(IOD34)
               FAC34I = FAC34(IOD34)
               EXPPQI = EXPP + EXPQ
               FACTOR = FAC12I*FAC34I/SQRT(EXPPQI)
               IF (ABS(FACTOR) .GT. THRESH) THEN
                  NOINT = .FALSE.
                  ALPHA = EXPP*EXPQ/EXPPQI
                  PQXI = PX - COOR34(IOD34,1)
                  PQYI = PY - COOR34(IOD34,2)
                  PQZI = PZ - COOR34(IOD34,3)
                  IF (ABS(PQXI) .GT. THRESH) IPQ0X = 0
                  IF (ABS(PQYI) .GT. THRESH) IPQ0Y = 0
                  IF (ABS(PQZI) .GT. THRESH) IPQ0Z = 0
                  PQX(IODS) = SIGN*PQXI
                  PQY(IODS) = SIGN*PQYI
                  PQZ(IODS) = SIGN*PQZI
                  WVAL = ALPHA*(PQXI*PQXI + PQYI*PQYI + PQZI*PQZI)
                  CALL GAMFUN
                  TALPHA = ALPHA + ALPHA
                  DO 320 I = 0, JMAX
                     RJ000(IODS,I) = FACTOR*FJW(I)
                     FACTOR = - TALPHA*FACTOR
  320             CONTINUE
               ELSE
                  DO 325 I = 0 ,JMAX
                     RJ000(IODS,I) = D0
  325             CONTINUE
               END IF
  310       CONTINUE
  300    CONTINUE
      END IF
C
C     *************************
C     ***** PRINT SECTION *****
C     *************************
C
      IF (IPRINT .GT. 10) THEN
         WRITE (LUPRI, 1000)
         WRITE (LUPRI, 1010) JMAX
         WRITE (LUPRI, 1020) NUC12, NUC34
         WRITE (LUPRI, 1030) THRESH
         WRITE (LUPRI, 1040) ONECEN
         WRITE (LUPRI, 1045) NOINT
         WRITE (LUPRI, 1050) NUABCD
         IF (IPRINT .GT. 20) THEN
            WRITE (LUPRI, 1100)
            ISTART = 0
            DO 2000 J = 0, JMAX
               WRITE (LUPRI, 1110) J
               IADR = 0
               DO 2100 I = 1, NUC12
                  WRITE (LUPRI, 1120) I
                  WRITE (LUPRI, 1130) (RJ000(IADR + K,J), K = 1, NUC34)
                  IADR = IADR + NUC34
 2100          CONTINUE
 2000       CONTINUE
         END IF
      END IF
 1000 FORMAT (//,' ********** SUBROUTINE R000 **********')
 1010 FORMAT (//,'  JMAX    ',I7)
 1020 FORMAT (   '  NUC     ',2I7)
 1030 FORMAT (   '  THRESH  ',1P,D12.4)
 1040 FORMAT (   '  ONECEN  ',L7)
 1045 FORMAT (   '  NOINT   ',L7)
 1050 FORMAT (   '  NUABCD  ',I7)
 1100 FORMAT(//,' ***** RJ000 - INTEGRALS *****')
 1110 FORMAT( /,'  J     ',I7)
 1120 FORMAT( /,'  NUC12 ',I7,/)
 1130 FORMAT(1P,6D12.4)
      RETURN
      END
#endif
