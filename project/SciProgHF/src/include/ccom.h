      LOGICAL DOCART, SPH(MXQN), SPHNRM
      LOGICAL DOSPHE
      REAL*8 THRS
      INTEGER NHTYP, IUTYP, KHK(MXQN), KCK(MXQN), NHKOFF(MXQN)
      COMMON /CCOM/ THRS, NHTYP, DOCART, IUTYP, SPHNRM, KHK, KCK, SPH,  &
     &              NHKOFF, DOSPHE

      CHARACTER*4 GTOTYP(MXQN*(MXQN+1)*(MXQN+2)/6)
      COMMON /CCOMC/ GTOTYP
