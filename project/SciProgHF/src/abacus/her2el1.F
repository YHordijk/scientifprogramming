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
C  /* Deck c1driv */
      SUBROUTINE C1DRIV(HERINT,INDHER,HCINT,COEF12,CONT1,CONT2,
     &                  WORK,LWORK,NPCO1,NPCO2,NUCS12,INDHSQ,IODDHR,
     &                  IPRINT,LMNV12,IODD12,NPNT12,NRED12,NHCINT)
C
C     TUH
C
#include "implicit.h"
#include "priunit.h"
#include "maxaqn.h"
#include "iratdef.h"
#include "twoao.h"
#include "twosta.h"
      INTEGER TUV
      COMMON /DHCINF/ IHCADR(10), IHCSYM(10)
      DIMENSION HERINT(NU1234,*),
     &          HCINT(NCCPP,NTUV34,KHKT12,NHCINT),
     &          NPCO1(*), NPCO2(*), NUCS12(*),
     &          COEF12(*), CONT1(*),  CONT2(*), INDHSQ(*), IODDHR(*),
     &          LMNV12(*), IODD12(KCKT12,2),
     &          NPNT12(*), NRED12(*), WORK(LWORK)

C
      CALL QENTER('C1DRIV')
#include "memint.h"
      IF (IPRINT .GT. 5) CALL TITLER('Output from C1DRIV','*',103)
C
C     *************************
C     ***** PRINT SECTION *****
C     *************************
C
      IF (IPRINT .GE. 10) THEN
         WRITE (LUPRI, 1020) IDERIV
         WRITE (LUPRI, 1040) DC10
         WRITE (LUPRI, 1060) DC1E
         WRITE (LUPRI, 1070) NHKT1, NHKT2
         WRITE (LUPRI, 1080) KCKT1, KCKT2, KCKT12
         WRITE (LUPRI, 1095) NUC1, NUC2
         WRITE (LUPRI, '(A,2I7)') 'NUCR1/2 ',NUCR1,NUCR2
         WRITE (LUPRI, 1100) NUC12, NUC34
         WRITE (LUPRI, '(A,2I7)') 'NORB1/2 ',NORB1,NORB2
         WRITE (LUPRI, '(A,2I7)') 'NORR1/2 ',NORR1,NORR2
         WRITE (LUPRI, 1110) NORB12
         WRITE (LUPRI, 1130) DIAG12
         WRITE (LUPRI, 1160) IHRSYM
         WRITE (LUPRI, 1170) I120X, I120Y, I120Z
         WRITE (LUPRI, 1180) NU1234
         WRITE (LUPRI, '(A,2L5)') 'RPRI12, RCNT12 ',RPRI12, RCNT12
      END IF
C
C     Work space for general contraction:
C
      IF (GEN12) THEN
         LSCR1 = NUCR1*NORR2*NUC34
         LSCR2 = NUCR1*NUCR2*NUC34
      ELSE
         LSCR1 = 0
         LSCR2 = 0
      END IF
C
C
C     Undifferentiated integrals
C     ==========================
C
      IF (DC10) THEN
C
C        Work space usage in C10INT:
C
C        HCCONT  | HCPRIM | ETUV
C                |        | SCR1 | SCR2
C                |
C                | HCSINT
C
         IF (KHKT12 .EQ. 1) THEN
            LETUV  = 0
            LHCPRM = 0
         ELSE
            LETUV  = NU1234
            LHCPRM = NU1234*NTUV34
         END IF
         LCCONT = 0
         LCSINT = 0
         IF (SPHR12)            LCCONT = NCCPP*NTUV34*KCKT12
         IF (SPHR1 .AND. SPHR2) LCSINT = NCCPP*NTUV34*KHKT2
C
C
         CALL MEMGET2('REAL','CCONT',KCCONT,LCCONT,WORK,KFREE,LFREE)
         LNGTH1 = LHCPRM + LETUV
         LNGTH2 = LHCPRM + LSCR1 + LSCR2
         LNGTH3 = LCSINT
         LBUF   = MAX(LNGTH1,LNGTH2,LNGTH3)
         CALL MEMGET2('REAL','BUF',KBUF,LBUF,WORK,KFREE,LFREE)
         KCSINT = KBUF
         KHCPRM = KBUF
         KETUV  = KHCPRM + LHCPRM
         KSCR1  = KHCPRM + LHCPRM
         KSCR2  = KSCR1  + LSCR1
         MWC1DR = MAX(MWC1DR,KFREE)
         LWTOT  = LWTOT + KFREE - 1
         MWTOT  = MAX(MWTOT,LWTOT)
C
         IF (TKTIME) TIMSTR = SECOND()
         CALL C10INT(HERINT,INDHER,INDHER,IODDHR,INDHSQ,HCINT,
     &               WORK(KCSINT),WORK(KCCONT),WORK(KETUV),WORK(KHCPRM),
     &               COEF12,CONT1,CONT2,WORK(KSCR1),WORK(KSCR2),IPRINT,
     &               LMNV12,IODD12,NPCO1,NPCO2,NUCS12,NPNT12,NRED12)
         IF (TKTIME) TC10IN = TC10IN + SECOND() - TIMSTR
         LWTOT  = LWTOT - KFREE + 1
         CALL MEMREL('C1DRIV.C10INT',WORK,KWORK,KWORK,KFREE,LFREE)
      END IF
C
C     Derivatives integrals
C     =====================
C
      IF (DC1E) THEN
C
C        Work space usage in C1EINT:
C
C        KODD12 | HCCONT  | HCPRIM | ETUV
C                         |        | SCR1 | SCR2
C                         |
C                         | HCSINT
C
         LODD12 = 2*KCKT12
         LETUV  = NU1234
         LHCPRM = NU1234*KTUV34
         LCCONT = 0
         LCSINT = 0
         IF (SPHR12)            LCCONT = NCCPP*KTUV34*KCKT12
         IF (SPHR1 .AND. SPHR2) LCSINT = NCCPP*KTUV34*KHKT2
C
         CALL MEMGET('INTE',KODD12,LODD12,WORK,KFREE,LFREE)
         CALL MEMGET('REAL',KCCONT,LCCONT,WORK,KFREE,LFREE)
         LNGTH1 = LHCPRM + LETUV
         LNGTH2 = LHCPRM + LSCR1 + LSCR2
         LNGTH3 = LCSINT
         LBUF   = MAX(LNGTH1,LNGTH2,LNGTH3)
         CALL MEMGET('REAL',KBUF  ,LBUF  ,WORK,KFREE,LFREE)
         KHCPRM = KBUF
         KCSINT = KBUF
         KETUV  = KHCPRM + LHCPRM
         KSCR1  = KHCPRM + LHCPRM
         KSCR2  = KSCR1  + LSCR1
C
         MWC1DR = MAX(MWC1DR,KFREE)
         LWTOT  = LWTOT + KFREE - 1
         MWTOT  = MAX(MWTOT,LWTOT)
C
C
         IF (TKTIME) TIMSTR = SECOND()
         CALL C1EINT(HERINT,INDHER,INDHER,IODDHR,INDHSQ,HCINT,COEF12,
     &               CONT1,CONT2,WORK(KETUV),WORK(KHCPRM),WORK(KCCONT),
     &               WORK(KCSINT),WORK(KSCR1),WORK(KSCR2),LMNV12,IPRINT,
     &               NPCO1,NPCO2,NUCS12,NPNT12,NRED12,NHCINT,IODD12,
     &               WORK(KODD12))
         IF (TKTIME) TC1EIN = TC1EIN + SECOND() - TIMSTR
C
         LWTOT  = LWTOT - KFREE + 1
         CALL MEMREL('C1DRIV.C1EINT',WORK,KWORK,KWORK,KFREE,LFREE)
      END IF
C
C     Print Hermite-Spherical integrals
C     =================================
C
      IF (IPRINT .GE. 20) THEN
         NTOT = NCCPP*NTUV34*KHKT12
         IF (NHCINT.GT.1) NTOT = NTOT + NCCPP*KTUV34*KHKT12*(NHCINT - 1)
         CALL HEADER('Hermite-spherical integrals in C1DRIV',-1)
         WRITE (LUPRI,'(7X,A, I5)')'# integral types:',NHCINT
         WRITE (LUPRI,'(7X,A,2I5)')'# components:    ',KHKT1,KHKT2
         WRITE (LUPRI,'(7X,A, I5)')'Columns (NORB12):',NORB12
         WRITE (LUPRI,'(7X,A, I5)')'Rows    (NUC34): ',NUC34
         WRITE (LUPRI,'(7X,A, I5)')'# integrals:     ',NTOT
         DO 600 IHCINT = 1, NHCINT
            MTUV34 = KTUV34
            IF (DC10 .AND. IHCINT .EQ. 1) MTUV34 = NTUV34
            ICMP12 = 0
            DO 610 ICOMP1 = 1, KHKT1
               MAX2 = KHKT2
               IF (DIAG12) MAX2 = ICOMP1
               DO 620 ICOMP2 = 1, MAX2
                  ICMP12 = ICMP12 + 1
                  IODD = IEOR(IODD12(ICMP12,2),IHCSYM(IHCINT))
                  DO 630 TUV = 1, MTUV34
                  IF (IODDHR(TUV) .EQ. IODD) THEN
                     WRITE (LUPRI,'(/A,I3,A,2I3,A,I3)' )
     &                  ' Integral type:', IHCINT,
     &                  ' Components:   ', ICOMP1,ICOMP2,
     &                  ' TUV:          ', TUV
                     CALL OUTPUT(HCINT(1,TUV,ICMP12,IHCINT),
     &                           1,NUC34,1,NORB12,NUC34,NORB12,
     &                           1,LUPRI)
                  END IF
  630             CONTINUE
  620          CONTINUE
  610       CONTINUE
  600    CONTINUE
      END IF
      CALL QEXIT('C1DRIV')
      RETURN
 1020 FORMAT ('IDERIV   ',I7)
 1040 FORMAT ('DC10     ',L7)
 1060 FORMAT ('DC1E     ',L7)
 1070 FORMAT ('NHKT     ',2I7)
 1080 FORMAT ('KCKT     ',2I7,/'KCKT12   ',I7)
 1095 FORMAT ('NUC1/2   ',2I7)
 1100 FORMAT ('NUC12/34 ',2I7)
 1110 FORMAT ('NORB12   ',I7)
 1130 FORMAT ('DIAG12   ',L7)
 1160 FORMAT ('IHRSYM   ',I7)
 1170 FORMAT ('I120     ',3I7)
 1180 FORMAT ('NU1234   ',I7)
      END
C  /* Deck c10int */
      SUBROUTINE C10INT(HERINT,INDHER,INDHVC,IODDHR,INDHSQ,HCINT,
     &                  HCSINT,HCCONT,ETUV,HCPRIM,COEF12,CONT1,CONT2,
     &                  SCR1,SCR2,IPRINT,LMNV12,IODD12,
     &                  NPCO1,NPCO2,NUCS12,NPNT12,NRED12)
C
C     TUH
C
#include "implicit.h"
#include "priunit.h"
#include "maxaqn.h"
      INTEGER T, U, V, TUV
#include "twoao.h"
#include "hertop.h"
#include "sphtrm.h"
      COMMON /DHCINF/ IHCADR(10), IHCSYM(10)
      DIMENSION HERINT(NU1234,*), INDHER(0:JTOP,0:JTOP,0:JTOP),
     &          INDHVC(0:*), IODDHR(*), INDHSQ(*),
     &          COEF12(MXUC12,0:JMAX1+JMAX2,0:JMAX1,0:JMAX2,3,*),
     &          ETUV(NU1234), HCPRIM(NU1234,NTUV34),
     &          HCCONT(NCCPP,NTUV34,KCKT12),
     &          HCINT(NCCPP,NTUV34,KHKT12),
     &          HCSINT(*), SCR1(*), SCR2(*), CONT1(*), CONT2(*),
     &          LMNV12(KCKMX,5,2), IODD12(KCKT12,2),
     &          NPCO1(*), NPCO2(*), NUCS12(*), NPNT12(*), NRED12(*)
C

C
      IF (IPRINT .GT. 5) CALL TITLER('Output from C10INT','*',103)
C
C     COMMON /DHCINF/
C     ---------------
C
      IHCADR(1) = 1
      IHCSYM(1) = 0
C
C     *********************************
C     ***** Special Case: (ss|xy) *****
C     *********************************
C
      IF (KHKT12 .EQ. 1) THEN
         JODD12 = 0
         CALL C1CONT(HERINT,HCINT,CONT1,CONT2,SCR1,SCR2,IODDHR,JODD12,
     &               NTUV34,NPCO1,NPCO2,NUCS12,NPNT12,NRED12)
C
C     *********************************
C     ***** General Case: (xy|zw) *****
C     *********************************
C
      ELSE
         INCRMT = I120X + 1
         INCRMU = I120Y + 1
         INCRMV = I120Z + 1
         ICMP12 = 0
         DO 100 ICOMP1 = 1,KCKT1
            L1 = LMNV12(ICOMP1,1,1)
            M1 = LMNV12(ICOMP1,2,1)
            N1 = LMNV12(ICOMP1,3,1)
            MAX2 = KCKT2
            IF (DIAC12) MAX2 = ICOMP1
            DO 200 ICOMP2 = 1,MAX2
               ICMP12 = ICMP12 + 1
C
C              Primitive integrals
C              ===================
C
               L2 = LMNV12(ICOMP2,1,2)
               M2 = LMNV12(ICOMP2,2,2)
               N2 = LMNV12(ICOMP2,3,2)
               MAXT = L1 + L2
               MAXU = M1 + M2
               MAXV = N1 + N2
               MINT = IAND(MAXT,INCRMT - 1)
               MINU = IAND(MAXU,INCRMU - 1)
               MINV = IAND(MAXV,INCRMV - 1)
               IF (IPRINT .GE. 10) THEN
                  WRITE (LUPRI,'(A,2I5)')'ICOMP1/2: ',ICOMP1,ICOMP2
                  WRITE (LUPRI,'(A,3I5)')'L/M/N1:',L1,M1,N1
                  WRITE (LUPRI,'(A,3I5)')'L/M/N2:',L2,M2,N2
                  WRITE (LUPRI,'(A,3I5)')'Loop parameters T:',
     &                                    MINT,MAXT,INCRMT
                  WRITE (LUPRI,'(A,3I5)')'Loop parameters U:',
     &                                    MINU,MAXU,INCRMU
                  WRITE (LUPRI,'(A,3I5)')'Loop parameters V:',
     &                                    MINV,MAXV,INCRMV
               END IF
               CALL DZERO(HCPRIM,NTUV34*NU1234)
C
               DO 300 V = MINV, MAXV, INCRMV
               DO 300 U = MINU, MAXU, INCRMU
               DO 300 T = MINT, MAXT, INCRMT
C
                  DO 400 I = 1, NUC12
                     ECOEFI = COEF12(I,T,L1,L2,1,1)
     &                      * COEF12(I,U,M1,M2,2,1)
     &                      * COEF12(I,V,N1,N2,3,1)
                     IJ = (I - 1)*NUC34
                     DO 410 J = 1, NUC34
                        ETUV(IJ + J) = ECOEFI
  410                CONTINUE
  400             CONTINUE
C
                  ITUV = INDHER(T,U,V)
                  IODD = IODDHR(ITUV)
                  INDS = INDHSQ(ITUV)
                  DO 500 TUV = 1, NTUV34
                  IF (IODD .EQ. IODDHR(TUV)) THEN
                     INDT = INDS + INDHSQ(TUV)
                     INDT = INDHVC(INDT)
                     DO 510 I = 1, NU1234
                        HCPRIM(I,TUV) = HCPRIM(I,TUV)
     &                        + ETUV(I)*HERINT(I,INDT)
  510                CONTINUE
                  END IF
C
  500             CONTINUE
  300          CONTINUE
C
C              Contracted integrals
C              ====================
C
               JODD12 = IODD12(ICMP12,1)
               IF (SPHR12) THEN
                  CALL C1CONT(HCPRIM,HCCONT(1,1,ICMP12),CONT1,CONT2,
     &                        SCR1,SCR2,IODDHR,JODD12,NTUV34,
     &                        NPCO1,NPCO2,NUCS12,NPNT12,NRED12)
               ELSE
                  CALL C1CONT(HCPRIM,HCINT(1,1,ICMP12),CONT1,CONT2,
     &                        SCR1,SCR2,IODDHR,JODD12,NTUV34,
     &                        NPCO1,NPCO2,NUCS12,NPNT12,NRED12)
               END IF
  200       CONTINUE
  100    CONTINUE
C
C        Spherical integrals
C        ===================
C
         IF (SPHR12) THEN
            CALL C1SPHR(HCCONT,HCINT,HCSINT,CSP(ISPADR(NHKT1)),
     &                  CSP(ISPADR(NHKT2)),IODDHR,IODD12,NTUV34,IPRINT)
         END IF
      END IF
      RETURN
      END
C  /* Deck c1eint */
      SUBROUTINE C1EINT(HERINT,INDHER,INDHVC,IODDHR,INDHSQ,HCINT,COEF12,
     &                  CONT1,CONT2,ETUV,HCPRIM,HCCONT,HCSINT,SCR1,SCR2,
     &                  LMNV12,IPRINT,NPCO1,NPCO2,NUCS12,NPNT12,NRED12,
     &                  NHCINT,IODD12,KODD12)
C
C     TUH
C
#include "implicit.h"
#include "priunit.h"
#include "maxaqn.h"
      INTEGER T, U, V, TUV
#include "twoao.h"
#include "hertop.h"
#include "sphtrm.h"
#include "crsdir.h"
      COMMON /DHCINF/ IHCADR(10), IHCSYM(10)
      DIMENSION JOFFEX(7), JOFFEY(7), JOFFEZ(7),
     &          INCMXT(3), INCMXU(3), INCMXV(3),
     &          JSTRAT(3), JENDAT(3)
      DIMENSION HERINT(NU1234,*),
     &          HCINT(NCCPP,NTUV34,KHKT12,NHCINT),
     &          HCCONT(NCCPP,KTUV34,KCKT12),
     &          HCSINT(NCCPP,KTUV34,KHKT2),
     &          HCPRIM(NU1234,KTUV34), ETUV(NU1234),
     &          INDHER(0:JTOP,0:JTOP,0:JTOP),
     &          INDHVC(0:*), IODDHR(*), INDHSQ(*),
     &          COEF12(MXUC12,0:JMAX1+JMAX2,0:JMAX1,0:JMAX2,3,*),
     &          LMNV12(KCKMX,5,2), IODD12(KCKT12,2), KODD12(KCKT12,2),
     &          SCR1(*), SCR2(*), CONT1(*), CONT2(*),
     &          NPCO1(*), NPCO2(*), NUCS12(*), NPNT12(*), NRED12(*)

C
      IF (IPRINT .GT. 5) CALL TITLER('Output from C1EINT','*',103)
C
      ICOOR  = 0
      IHCINT = 1
C
C     ***** x direction *****
C
      IF (DHCEX) THEN
         ICOOR = ICOOR + 1
         JSTRAT(ICOOR) = IHCINT + 1
         INCMXT(ICOOR) = 1
         INCMXU(ICOOR) = 0
         INCMXV(ICOOR) = 0
         IF (DHCEX1) THEN
            IHCINT = IHCINT + 1
            JOFFEX(IHCINT) = 2
            JOFFEY(IHCINT) = 1
            JOFFEZ(IHCINT) = 1
            IHCSYM(IHCINT) = IAND(IHRSYM,1)
            IHCADR(3) = IHCINT
         END IF
         IF (DHCEX2) THEN
            IHCINT = IHCINT + 1
            JOFFEX(IHCINT) = 3
            JOFFEY(IHCINT) = 1
            JOFFEZ(IHCINT) = 1
            IHCSYM(IHCINT) = IAND(IHRSYM,1)
            IHCADR(4) = IHCINT
         END IF
         JENDAT(ICOOR) = IHCINT
      END IF
C
C     ***** y direction *****
C
      IF (DHCEY) THEN
         ICOOR = ICOOR + 1
         JSTRAT(ICOOR) = IHCINT + 1
         INCMXT(ICOOR) = 0
         INCMXU(ICOOR) = 1
         INCMXV(ICOOR) = 0
         IF (DHCEY1) THEN
            IHCINT = IHCINT + 1
            JOFFEX(IHCINT) = 1
            JOFFEY(IHCINT) = 2
            JOFFEZ(IHCINT) = 1
            IHCSYM(IHCINT) = IAND(IHRSYM,2)
            IHCADR(6) = IHCINT
         END IF
         IF (DHCEY2) THEN
            IHCINT = IHCINT + 1
            JOFFEX(IHCINT) = 1
            JOFFEY(IHCINT) = 3
            JOFFEZ(IHCINT) = 1
            IHCSYM(IHCINT) = IAND(IHRSYM,2)
            IHCADR(7) = IHCINT
         END IF
         JENDAT(ICOOR) = IHCINT
      END IF
C
C     ***** z direction *****
C
      IF (DHCEZ) THEN
         ICOOR = ICOOR + 1
         JSTRAT(ICOOR) = IHCINT + 1
         INCMXT(ICOOR) = 0
         INCMXU(ICOOR) = 0
         INCMXV(ICOOR) = 1
         IF (DHCEZ1) THEN
            IHCINT = IHCINT + 1
            JOFFEX(IHCINT) = 1
            JOFFEY(IHCINT) = 1
            JOFFEZ(IHCINT) = 2
            IHCSYM(IHCINT) = IAND(IHRSYM,4)
            IHCADR(9) = IHCINT
         END IF
         IF (DHCEZ2) THEN
            IHCINT = IHCINT + 1
            JOFFEX(IHCINT) = 1
            JOFFEY(IHCINT) = 1
            JOFFEZ(IHCINT) = 3
            IHCSYM(IHCINT) = IAND(IHRSYM,4)
            IHCADR(10) = IHCINT
         END IF
         JENDAT(ICOOR) = IHCINT
      END IF
      NCOOR = ICOOR
      IF (NHCINT .NE. IHCINT) CALL QUIT('NHCINT error in C1EINT')
      IF (IPRINT .GE. 10) THEN
         WRITE (LUPRI, 1020) DHCEX, DHCEX1, DHCEX2
         WRITE (LUPRI, 1030) DHCEY, DHCEY1, DHCEY2
         WRITE (LUPRI, 1040) DHCEZ, DHCEZ1, DHCEZ2
         WRITE (LUPRI, 1050) NCOOR
         WRITE (LUPRI, 1060) NHCINT
         WRITE (LUPRI, 1070) KTUV34
         WRITE (LUPRI, 1080) (INCMXT(I), I = 1, NCOOR)
         WRITE (LUPRI, 1090) (INCMXU(I), I = 1, NCOOR)
         WRITE (LUPRI, 1100) (INCMXV(I), I = 1, NCOOR)
         WRITE (LUPRI, 1120) (JOFFEX(I), I = 1, NHCINT)
         WRITE (LUPRI, 1130) (JOFFEY(I), I = 1, NHCINT)
         WRITE (LUPRI, 1140) (JOFFEZ(I), I = 1, NHCINT)
      END IF
C
      INCRMT = I120X + 1
      INCRMU = I120Y + 1
      INCRMV = I120Z + 1
C
      DO 100 ICOOR = 1, NCOOR
      DO 100 IHCINT = JSTRAT(ICOOR), JENDAT(ICOOR)
         ITYPEX = JOFFEX(IHCINT)
         ITYPEY = JOFFEY(IHCINT)
         ITYPEZ = JOFFEZ(IHCINT)
         IF (IPRINT .GE. 10) THEN
            WRITE (LUPRI,'(A,2I5)')
     &         'Integral type (ICOOR,IHCINT):',ICOOR,IHCINT
            WRITE (LUPRI,'(A,3I5)')
     &         'ITYPEX,ITYPEY,ITYPEZ:       ',ITYPEX,ITYPEY,ITYPEZ
            WRITE (LUPRI,'(A,I5)') ' ICOOR ', ICOOR
         END IF
         DO 110 I = 1, KCKT12
            KODD12(I,1) = IEOR(IODD12(I,1),IHCSYM(IHCINT))
            KODD12(I,2) = IEOR(IODD12(I,2),IHCSYM(IHCINT))
  110    CONTINUE
         ICMP12 = 0
         DO 200 ICOMP1 = 1, KCKT1
            L1 = LMNV12(ICOMP1,1,1)
            M1 = LMNV12(ICOMP1,2,1)
            N1 = LMNV12(ICOMP1,3,1)
            MAX2 = KCKT2
            IF (DIAC12) MAX2 = ICOMP1
            DO 210 ICOMP2 = 1, MAX2
               ICMP12 = ICMP12 + 1
               L2 = LMNV12(ICOMP2,1,2)
               M2 = LMNV12(ICOMP2,2,2)
               N2 = LMNV12(ICOMP2,3,2)
C
C              Primitive integrals
C              ===================
C
               MAXT = L1 + L2 + INCMXT(ICOOR)
               MAXU = M1 + M2 + INCMXU(ICOOR)
               MAXV = N1 + N2 + INCMXV(ICOOR)
               MINT = IAND(MAXT,INCRMT - 1)
               MINU = IAND(MAXU,INCRMU - 1)
               MINV = IAND(MAXV,INCRMV - 1)
               IF (IPRINT .GE. 10) THEN
                  WRITE (LUPRI,'(A,2I5)')'ICOMP1/2:',ICOMP1,ICOMP2
                  WRITE (LUPRI,'(A,3I5)')'L/M/N1:',L1,M1,N1
                  WRITE (LUPRI,'(A,3I5)')'L/M/N2:',L2,M2,N2
                  WRITE (LUPRI,'(A,3I5)')'Loop parameters T:',
     &                                       MINT,MAXT,INCRMT
                  WRITE (LUPRI,'(A,3I5)')'Loop parameters U:',
     &                                       MINU,MAXU,INCRMU
                  WRITE (LUPRI,'(A,3I5)')'Loop parameters V:',
     &                                       MINV,MAXV,INCRMV
               END IF
C
               CALL DZERO(HCPRIM,NU1234*KTUV34)
               DO 300 V = MINV, MAXV, INCRMV
               DO 300 U = MINU, MAXU, INCRMU
               DO 300 T = MINT, MAXT, INCRMT
C
C                 Expansion coefficients
C
                  IJ = 0
                  DO 400 I = 1, NUC12
                     ECOEFI = COEF12(I,T,L1,L2,1,ITYPEX)
     &                      * COEF12(I,U,M1,M2,2,ITYPEY)
     &                      * COEF12(I,V,N1,N2,3,ITYPEZ)
                     DO 410 J = 1, NUC34
                        IJ = IJ + 1
                        ETUV(IJ) = ECOEFI
  410                CONTINUE
  400             CONTINUE
C
C                 Hermite-Cartesian integrals
C
                  ITUV = INDHER(T,U,V)
                  IODD = IODDHR(ITUV)
                  INDS = INDHSQ(ITUV)
                  DO 500 TUV = 1, KTUV34
                  IF (IODD .EQ. IODDHR(TUV)) THEN
                     INDT = INDS + INDHSQ(TUV)
                     INDT = INDHVC(INDT)
                     DO 510 I = 1, NU1234
                        HCPRIM(I,TUV) = HCPRIM(I,TUV)
     &                        + ETUV(I)*HERINT(I,INDT)
  510                CONTINUE
                  END IF
  500             CONTINUE
  300          CONTINUE
C
C              Contracted integrals
C              ====================
C
               IODDCH = IODDHR(INDHER(MAXT,MAXU,MAXV))
               IODD   = KODD12(ICMP12,1)
               if (iodd .ne. ioddch ) stop 'iodd incorrect '
               IF (SPHR12) THEN
                  CALL C1CONT(HCPRIM,HCCONT(1,1,ICMP12),CONT1,CONT2,
     &                        SCR1,SCR2,IODDHR,IODDCH,KTUV34,NPCO1,
     &                        NPCO2,NUCS12,NPNT12,NRED12)
               ELSE
                  CALL C1CONT(HCPRIM,HCINT(1,1,ICMP12,IHCINT),CONT1,
     &                        CONT2,SCR1,SCR2,IODDHR,IODDCH,KTUV34,
     &                        NPCO1,NPCO2,NUCS12,NPNT12,NRED12)
               END IF
  210       CONTINUE
  200    CONTINUE
C
C        Spherical integrals
C        ===================
C
         IF (SPHR12) THEN
            CALL C1SPHR(HCCONT,HCINT(1,1,1,IHCINT),HCSINT,
     &                  CSP(ISPADR(NHKT1)),CSP(ISPADR(NHKT2)),
     &                  IODDHR,KODD12,KTUV34,IPRINT)
         END IF
  100 CONTINUE
      RETURN
 1020 FORMAT ('DHCEX(1/2)',3L7)
 1030 FORMAT ('DHCEY(1/2)',3L7)
 1040 FORMAT ('DHCEZ(1/2)',3L7)
 1050 FORMAT ('NCOOR     ',I7)
 1060 FORMAT ('NHCINT    ',I7)
 1070 FORMAT ('KTUV34    ',I7)
 1080 FORMAT ('INCMXT    ',(4I7))
 1090 FORMAT ('INCMXU    ',(4I7))
 1100 FORMAT ('INCMXV    ',(4I7))
 1120 FORMAT ('JOFFEX    ',(7I7))
 1130 FORMAT ('JOFFEY    ',(7I7))
 1140 FORMAT ('JOFFEZ    ',(7I7))
      END
C  /* Deck c1cont */
      SUBROUTINE C1CONT(HCPRIM,HCCNT,CONT1,CONT2,SCR1,SCR2,IODDHR,
     &                  IODDCH,NTUV,NPCO1,NPCO2,NUCS12,NPNT12,NRED12)
C
C     tuh Mar 1988
C     Modified for no transformations (NOCNT) tuh Apr 1989
C     Special case for segmented contractions tuh Feb 1992
C
C     Purpose: Transformation of two outermost indices
C              Index 1 is outermost index
C              Index 2 is next outermost index
C
C     Note: After transformation the order of two outermost indices
C           is reversed
C
C     In:  HCPRIM(NUC34,NUC12,NTUV)
C
C     Out: HCCNT(NUC34,NORB12,NTUV)
C
C     Scratch: SCR1(NUC34,NUCR1*NORR2)
C              SCR2(NUCR1*NUCR2*NUC34)
C
#include "implicit.h"
#include "priunit.h"
      PARAMETER (D1 = 1.0D0, D0 = 0.0D0)
      INTEGER TUV
      DIMENSION HCPRIM(NUC34,NUC12,NTUV), HCCNT(NUC34,NORB12,NTUV),
     &          CONT1(*), CONT2(*), NPCO1(NSET1,2), NPCO2(NSET2,2),
     &          NUCS12(*), IODDHR(*), NPNT12(NUC1*NUC2,2), NRED12(*),
     &          SCR1(NUC34,NUCR1*NORR2), SCR2(NUC34,NUCR1*NUCR2)
#include "twoao.h"
C
C     Case (i): No contraction
C     ========================
C
      IF (NOCNT) THEN
#ifndef OLD_NOCONT
C980827-hjaaj: now the NOCNT flag is controlled in CCDRIV
C              and it checks if a segmented contr. is uncontracted
         ISIZE = NUC34*NORB12
         DO TUV = 1,NTUV
            IF (IODDHR(TUV) .EQ. IODDCH)
     &         CALL DCOPY(NUC34*NORB12,HCPRIM(1,1,TUV),1,
     &                                 HCCNT(1,1,TUV),1)
         END DO
#else
C980827-hjaaj: old .NOCONT did not work, I have made
C              TWOINT stop if NOCONT is set.
         DO 100 TUV = 1, NTUV
         IF (IODDHR(TUV) .EQ. IODDCH) THEN
            IF (TPRI12) THEN
             NPRM12 = NUC2*(NUC2 + 1)/2
             CALL DCOPY(NPRM12*NUC34,HCPRIM(1,1,TUV),1,HCCNT(1,1,TUV),1)
            ELSE
               IJ = 1
               DO 110 I = 1, NUC2
                  DO 120 J = 1, NUC1
                     JI = (J - 1)*NUC2 + I
                     CALL DCOPY(NUC34,HCPRIM(1,IJ,TUV),1,
     &                                HCCNT (1,JI,TUV),1)
                     IJ = IJ + 1
  120             CONTINUE
  110          CONTINUE
            END IF
         END IF
  100    CONTINUE
#endif
C
C     Case (ii): General contraction
C     ==============================
C
      ELSE IF (GEN12) THEN
         NPR234 = NUCR1*NUC34
         NCT134 = NORR2*NUC34
         DO 200 TUV = 1, NTUV
         IF (IODDHR(TUV) .EQ. IODDCH) THEN
C
C           Transform first index
C           =====================
C
            IF (TPRI12) THEN
               IF (RPRI12) THEN
                  CALL DZERO(SCR2,NUCR1*NUCR2*NUC34)
                  DO 300 IJ = 1, NUC12
                     IOFFIJ = NPNT12(IJ,1)
                     IOFFJI = NPNT12(IJ,2)
                     IF (IOFFIJ .EQ. IOFFJI) THEN
                        DO 310 KL = 1, NUC34
                           SCR2(KL,IOFFIJ) = HCPRIM(KL,IJ,TUV)
  310                   CONTINUE
                     ELSE
                        DO 320 KL = 1, NUC34
                           SCR2(KL,IOFFIJ) = HCPRIM(KL,IJ,TUV)
                           SCR2(KL,IOFFJI) = HCPRIM(KL,IJ,TUV)
  320                   CONTINUE
                     END IF
  300             CONTINUE
               ELSE
                  IJ = 0
                  DO 400 I = 1, NUC2
                     DO 410 J = 1, I - 1
                        IJ = IJ + 1
                        IOFFIJ = (I - 1)*NUC2 + J
                        IOFFJI = (J - 1)*NUC2 + I
                        DO 420 KL = 1, NUC34
                           SCR2(KL,IOFFIJ) = HCPRIM(KL,IJ,TUV)
                           SCR2(KL,IOFFJI) = HCPRIM(KL,IJ,TUV)
  420                   CONTINUE
  410                CONTINUE
                     IJ = IJ + 1
                     IOFFIJ = (I - 1)*NUC2 + J
                     DO 430 KL = 1, NUC34
                        SCR2(KL,IOFFIJ) = HCPRIM(KL,IJ,TUV)
  430                CONTINUE
  400             CONTINUE
               END IF
               CALL DGEMM('N','N',NPR234,NORR2,NUCR2,D1,SCR2,NPR234,
     &              CONT2,NUCR2,D0,SCR1,NPR234)
            ELSE
               IF (RPRI12) THEN
                  CALL DZERO(SCR2,NUCR1*NUCR2*NUC34)
                  DO 500 IJ = 1, NUC12
                     IOFFIJ = NPNT12(IJ,1)
                     DO 510 KL = 1, NUC34
                        SCR2(KL,IOFFIJ) = HCPRIM(KL,IJ,TUV)
  510                CONTINUE
  500             CONTINUE
                  CALL DGEMM('N','N',NPR234,NORR2,NUCR2,D1,SCR2,NPR234,
     &                 CONT2,NUCR2,D0,SCR1,NPR234)
               ELSE
                 CALL DGEMM('N','N',NPR234,NORR2,NUCR2,D1,
     &                HCPRIM(1,1,TUV),NPR234,CONT2,NUCR2,D0,SCR1,NPR234)
               END IF
            END IF
C
C           Change order of first and second indices
C           ========================================
C
            IJ1 = 1
            DO 600 I = 1, NORR2
               IJ2 = I
               DO 610 J = 1, NUCR1
                  DO 620 KL = 1, NUC34
                     SCR2(KL,IJ2) = SCR1(KL,IJ1)
  620             CONTINUE
                  IJ1 = IJ1 + 1
                  IJ2 = IJ2 + NORR2
  610          CONTINUE
  600       CONTINUE
C
C           Transform second index
C           ======================
C
            IF (TCON12 .OR. RCNT12) THEN
               CALL DGEMM('N','N',NCT134,NORR1,NUCR1,D1,SCR2,NCT134,
     &              CONT1,NUCR1,D0,SCR1,NCT134)
               DO 700 I = 1, NORB12
                 CALL DCOPY(NUC34,SCR1(1,NRED12(I)),1,HCCNT(1,I,TUV),1)
  700          CONTINUE
            ELSE
               CALL DGEMM('N','N',NCT134,NORR1,NUCR1,D1,SCR2,NCT134,
     &              CONT1,NUCR1,D0,HCCNT(1,1,TUV),NCT134)
            END IF
         END IF
  200    CONTINUE
C
C     Case (iii): Segmented contraction
C     =================================
C
      ELSE
         DO 800 TUV = 1, NTUV
            IF (IODDHR(TUV) .EQ. IODDCH) THEN
               IJSTR = 1
               DO 810 IJ = 1, NORB12
                  NPRIJ = NUCS12(IJ)
                  IF (NPRIJ .GT. 0) THEN
                     DO 820 KL = 1, NUC34
                        HCCNT(KL,IJ,TUV) = HCPRIM(KL,IJSTR,TUV)
  820                CONTINUE
                     DO 830 IJPRM = IJSTR + 1, IJSTR + NPRIJ - 1
                        DO 840 KL = 1, NUC34
                           HCCNT(KL,IJ,TUV) = HCCNT (KL,IJ,   TUV)
     &                                      + HCPRIM(KL,IJPRM,TUV)
  840                   CONTINUE
  830                CONTINUE
                     IJSTR = IJSTR + NPRIJ
                  ELSE
                     DO 850 KL = 1, NUC34
                        HCCNT(KL,IJ,TUV) = D0
  850                CONTINUE
                  END IF
  810          CONTINUE
            END IF
  800    CONTINUE
      END IF
      RETURN
      END
C  /* Deck c1sphr */
      SUBROUTINE C1SPHR(HCCONT,HCINT,HCSINT,CSP1,CSP2,IODDHR,IODD12,
     &                  MTUV34,IPRINT)
#include "implicit.h"
#include "priunit.h"
#include "maxaqn.h"
      PARAMETER (D0 = 0.0D0)
      INTEGER TUV
#include "twoao.h"
      DIMENSION HCCONT(NCCPP,MTUV34,KCKT12),
     &          HCSINT(NCCPP,MTUV34,KHKT2),
     &          HCINT(NCCPP,NTUV34,KHKT12),
     &          CSP1(KHKT1,KCKT1),
     &          CSP2(KHKT2,KCKT2),
     &          IODDHR(*), IODD12(KCKT12,2)
C
      IF (IPRINT .GT. 5) CALL TITLER('Output from C1SPHR','*',103)
C
      CALL DZERO(HCINT,NCCPP*NTUV34*KHKT12)
C
C     Transformation of both indices
C     ==============================
C
      IF (SPHR1 .AND. SPHR2) THEN
         DO 100 ICOMP1 = 1, KCKT1
C
C           First half transformation:
C
            CALL DZERO(HCSINT,NCCPP*MTUV34*KHKT2)
            DO 200 ICOMP2 = 1, KCKT2
               ICMP12 = (ICOMP1 - 1)*KCKT2 + ICOMP2
               JODD12 = IODD12(ICMP12,1)
               DO 210 IKOMP2 = 1, KHKT2
                  SPHFAC = CSP2(IKOMP2,ICOMP2)
                  IF (ABS(SPHFAC) .GT. D0) THEN
                     DO 220 TUV = 1, MTUV34
                     IF (IODDHR(TUV) .EQ. JODD12) THEN
                        DO 230 I = 1, NCCPP
                           HCSINT(I,TUV,IKOMP2) = HCSINT(I,TUV,IKOMP2)
     &                                   + SPHFAC*HCCONT(I,TUV,ICMP12)
  230                   CONTINUE
                     END IF
  220                CONTINUE
                  END IF
  210          CONTINUE
  200       CONTINUE
C
C           Second half transformation:
C
            IKMP12 = 0
            DO 300 IKOMP1 = 1, KHKT1
               SPHFAC = CSP1(IKOMP1,ICOMP1)
               IF (ABS(SPHFAC) .GT. D0) THEN
                  MAX2 = KHKT2
                  IF (DIAG12) MAX2 = IKOMP1
                  DO 310 IKOMP2 = 1, MAX2
                     IKMP12 = IKMP12 + 1
                     JODD12 = IODD12(IKMP12,2)
                     DO 320 TUV = 1, MTUV34
                     IF (IODDHR(TUV) .EQ. JODD12) THEN
                        DO 330 I = 1, NCCPP
                           HCINT(I,TUV,IKMP12) = HCINT(I,TUV,IKMP12)
     &                                 + SPHFAC*HCSINT(I,TUV,IKOMP2)
  330                   CONTINUE
                     END IF
  320                CONTINUE
  310             CONTINUE
               ELSE IF (DIAG12) THEN
                  IKMP12 = IKMP12 + IKOMP1
               ELSE
                  IKMP12 = IKMP12 + KHKT2
               END IF
  300       CONTINUE
C
  100    CONTINUE
C
C     Transformation of first index only
C     ==================================
C
      ELSE IF (SPHR1) THEN
         DO 400 ICOMP1 = 1, KCKT1
         DO 400 IKOMP1 = 1, KHKT1
            SPHFAC = CSP1(IKOMP1,ICOMP1)
            IF (ABS(SPHFAC) .GT. D0) THEN
            DO 410 IKOMP2 = 1, KHKT2
               ICMP12 = (ICOMP1 - 1)*KHKT2 + IKOMP2
               IKMP12 = (IKOMP1 - 1)*KHKT2 + IKOMP2
               JODD12 = IODD12(IKMP12,2)
               DO 420 TUV = 1, MTUV34
               IF (IODDHR(TUV) .EQ. JODD12) THEN
                  DO 430 I = 1, NCCPP
                     HCINT(I,TUV,IKMP12) = HCINT(I,TUV,IKMP12)
     &                           + SPHFAC*HCCONT(I,TUV,ICMP12)
  430             CONTINUE
               END IF
  420          CONTINUE
  410       CONTINUE
            END IF
  400    CONTINUE
C
C     Transformation of second index only
C     ===================================
C
      ELSE
         DO 500 ICOMP2 = 1, KCKT2
         DO 500 IKOMP2 = 1, KHKT2
            SPHFAC = CSP2(IKOMP2,ICOMP2)
            IF (ABS(SPHFAC) .GT. D0) THEN
            DO 510 IKOMP1 = 1, KHKT1
               ICMP12 = (IKOMP1 - 1)*KCKT2 + ICOMP2
               IKMP12 = (IKOMP1 - 1)*KHKT2 + IKOMP2
               JODD12 = IODD12(IKMP12,2)
               DO 520 TUV = 1, MTUV34
               IF (IODDHR(TUV) .EQ. JODD12) THEN
                  DO 530 I = 1, NCCPP
                     HCINT(I,TUV,IKMP12) = HCINT(I,TUV,IKMP12)
     &                           + SPHFAC*HCCONT(I,TUV,ICMP12)
  530             CONTINUE
               END IF
  520          CONTINUE
  510       CONTINUE
            END IF
  500    CONTINUE
      END IF
      RETURN
      END
