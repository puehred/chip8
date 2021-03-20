	;;***************************************************************************
	;;*                                                                         *
	;;*   This program is free software; you can redistribute it and/or modify  *
	;;*   it under the terms of the GNU General Public License as published by  *
	;;*   the Free Software Foundation; either version 2 of the License, or     *
	;;*   (at your option) any later version.                                   *
	;;*                                                                         *
	;;***************************************************************************

.area chip8 (REL)

.include "basic.h"

    ;; -----------------------------------------------
    ;; Calculates the RAM card size. Sizes are 0x8000
	;; (32k RAM card), 0x4000 (16k RAM card), 0x2000
	;; (8k RAM card) or 0x0000 (no RAM card).
	;; Return: A = The high byte of the RAM card size,
	;;         0x80, 0x40, 0x20 or 0x00
	;; Used Registers: A,B,X,Y,P,Q,C,Z,DP
	;; PC-1350/2500: 61 bytes  PC-1360: 12 bytes
	;; -----------------------------------------------	
chk_memcard::
.if __PC_1350__ + __PC_2500__ 
	RA
	LIB	0x20
	MV_BA_MINUS_1_TO_X					; X = Start address of 16k RAM card
	LIB 0x40
	MV_BA_MINUS_1_TO_Y					; Y = Start address of 8k RAM card
	LP REG_K
	EXAM								; K = 0 (A unchanged in both ROM calls)
	IXL
	PUSH								; Push original content of memory loc.
	RA
	STD									; Write 0 to memory loc.
	LDD									; Read it back
	CPIA 0
	JRNZP chkmem_0k						; if != 0, no RAM card
	IY
	LDD									; Read it from 8k RAM card image
	CPIA 0
	JRNZP chkmem_no8k1					; if == 0, maybe it's a 8k RAM card
	INCK
chkmem_no8k1:
	DX
	IX									; Bring DP back to value of X
	LIA 0xff
	STD									; Write ff to memory loc.
	LDD									; Read it back
	CPIA 0xff
	JRNZP chkmem_0k						; if != ff, no RAM card
	DY
	IY									; Bring DP back to value of Y
	LDD									; Read it from 8k RAM card image
	CPIA 0xff
	JRNZP chkmem_no8k2					; if == ff, it's a 8k RAM card
	INCK
chkmem_no8k2:
;	LIB 0x40							; 16k RAM card (B is still 40 from init.)
	CPIM 2								; Two matches in 8k RAM card image ==>
	JRNZP chkmem_cleanup
	LIB 0x20							;   8k RAM card
chkmem_cleanup:	
	POP
	LIDP 0x2000
	STD
	EXAB
	RTN

chkmem_0k:
	LIB 0
	JRM chkmem_cleanup

.else

	LIDP RAM_START_PTR+1
	LDD									; A = high byte of RAM start pointer
	ANIA 0x7f							; Move to 0 .. 32k
	LP REG_B
	LIB 0x80
	SBM									; B = 0x80 - A
	EXAM
	RTN

.endif
