*comdeck orbinf.inc $Revision$
*----------------------------------------------------------------------*
*     Global Variables describing chemical system                      *
*----------------------------------------------------------------------*
*     MXPIRR  - number of symmetries                                   *
*     nBas(i) - (i = 1, nSym), number of basis functions               *
*     nOrb(i) - (i = 1, nSym), number of orbitals                      *
*     nFro(i) - (i = 1, nSym), number of frozen orbitals               *
*     nOcc(i) - (i = 1, nSym), number of occupied orbitals             *
*     nDel(i) - (i = 1, nSym), number of orbitals deleted by linear    *
*               dependencies                                           *
*     nExt(i) - (i = 1, nSym), number of virtual orbitals              *
*                                                                      *
*----------------------------------------------------------------------*
*
      INTEGER nSym,
     &        nBas(MXPIRR),nOrb(MXPIRR),nOcc(MXPIRR),nFro(MXPIRR),
     &        nDel(MXPIRR),nExt(MXPIRR),NASH(MXPIRR),NISH(MXPIRR)
*
*  Just for using GSLIST/DAFILE, no later use:
*
      integer NRAS1(MXPIRR),NRAS2(MXPIRR),NRAS3(MXPIRR)
*
      Common /ORBINFX/ nBas,nOrb,nOcc,nFro,nDel,nExt,NASH,NISH,nSym
