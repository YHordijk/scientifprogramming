!     
!     nucdata.h
!
!     Data from the periodic table.
!
      CHARACTER(LEN=4), PARAMETER :: NUCLABEL(1:118)=(/                 &
     &  'H  ', 'He ', 'Li ', 'Be ', 'B  ',                              &
     &  'C  ', 'N  ', 'O  ', 'F  ', 'Ne ',                              &
     &  'Na ', 'Mg ', 'Al ', 'Si ', 'P  ',                              &
     &  'S  ', 'Cl ', 'Ar ', 'K  ', 'Ca ',                              &
     &  'Sc ', 'Ti ', 'V  ', 'Cr ', 'Mn ',                              &
     &  'Fe ', 'Co ', 'Ni ', 'Cu ', 'Zn ',                              &
     &  'Ga ', 'Ge ', 'As ', 'Se ', 'Br ',                              &
     &  'Kr ', 'Rb ', 'Sr ', 'Y  ', 'Zr ',                              &
     &  'Nb ', 'Mo ', 'Tc ', 'Ru ', 'Rh ',                              &
     &  'Pd ', 'Ag ', 'Cd ', 'In ', 'Sn ',                              &
     &  'Sb ', 'Te ', 'I  ', 'Xe ', 'Cs ',                              &
     &  'Ba ', 'La ', 'Ce ', 'Pr ', 'Nd ',                              &
     &  'Pm ', 'Sm ', 'Eu ', 'Gd ', 'Tb ',                              &
     &  'Dy ', 'Ho ', 'Er ', 'Tm ', 'Yb ',                              &
     &  'Lu ', 'Hf ', 'Ta ', 'W  ', 'Re ',                              &
     &  'Os ', 'Ir ', 'Pt ', 'Au ', 'Hg ',                              &
     &  'Tl ', 'Pb ', 'Bi ', 'Po ', 'At ',                              &
     &  'Rn ', 'Fr ', 'Ra ', 'Ac ', 'Th ',                              &
     &  'Pa ', 'U  ', 'Np ', 'Pu ', 'Am ',                              &
     &  'Cm ', 'Bk ', 'Cf ', 'Es ', 'Fm ',                              &
     &  'Md ', 'No ', 'Lr ', 'Rf ', 'Db ',                              &
     &  'Sg ', 'Bh ', 'Hs ', 'Mt ', 'Ds ',                              &
     &  'Rg ', 'Cn ', 'Nh ', 'Fl ', 'Mc ',                              &
     &  'Lv ', 'Ts ', 'Og '/)
! Nuclear mass refers to most abundant or most stable isotope
      REAL(KIND=8), PARAMETER :: NUCMASS(1:118)=(/                      &
     &    1.D0,   4.D0,   7.D0,   9.D0,  11.D0,                         &
     &   12.D0,  14.D0,  16.D0,  19.D0,  20.D0,                         &
     &   23.D0,  24.D0,  27.D0,  28.D0,  31.D0,                         &
     &   32.D0,  35.D0,  40.D0,  39.D0,  40.D0,                         &
     &   45.D0,  48.D0,  51.D0,  52.D0,  55.D0,                         &
     &   56.D0,  59.D0,  58.D0,  63.D0,  64.D0,                         &
     &   69.D0,  74.D0,  75.D0,  80.D0,  79.D0,                         &
     &   84.D0,  85.D0,  88.D0,  89.D0,  90.D0,                         &
     &   93.D0,  98.D0,  98.D0, 102.D0, 103.D0,                         &
     &  106.D0, 107.D0, 114.D0, 115.D0, 120.D0,                         &
     &  121.D0, 130.D0, 127.D0, 132.D0, 133.D0,                         &
     &  138.D0, 139.D0, 140.D0, 141.D0, 144.D0,                         &
     &  145.D0, 152.D0, 153.D0, 158.D0, 159.D0,                         &
     &  162.D0, 162.D0, 168.D0, 169.D0, 174.D0,                         &
     &  175.D0, 180.D0, 181.D0, 184.D0, 187.D0,                         &
     &  192.D0, 193.D0, 195.D0, 197.D0, 202.D0,                         &
     &  205.D0, 208.D0, 209.D0, 209.D0, 210.D0,                         &
     &  222.D0, 223.D0, 226.D0, 227.D0, 232.D0,                         &
     &  231.D0, 238.D0, 237.D0, 244.D0, 243.D0,                         &
     &  247.D0, 247.D0, 251.D0, 252.D0, 257.D0,                         &
     &  258.D0, 259.D0, 262.D0, 261.D0, 262.D0,                         &
     &  263.D0, 262.D0, 265.D0, 266.D0, 281.D0,                         &
     &  280.D0, 285.D0, 284.D0, 289.D0, 288.D0,                         &
     &  292.D0, 293.D0, 294.D0/)
