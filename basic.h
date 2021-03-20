	;;***************************************************************************
	;;*                                                                         *
	;;*   This program is free software; you can redistribute it and/or modify  *
	;;*   it under the terms of the GNU General Public License as published by  *
	;;*   the Free Software Foundation; either version 2 of the License, or     *
	;;*   (at your option) any later version.                                   *
	;;*                                                                         *
	;;***************************************************************************

	;; -----------------------------------------------
	;; BASIC and internal ROM memory addresses
	;; file     : basic.h
	;; author   : puehringer edgar
	;; date     : 14.05.2020                 
	;; assembler: as61860                    
	;; -----------------------------------------------

.ifndef basic_h
.define basic_h

.include "target.h"
.include "regs.h"

BAS_START_OFFS = 0x30					; Offset between memory start and start of basic program

.if __PC_1350__
BAS_START_PTR   = 0x6f01				; Pointer to BASIC start, low byte. High byte is +1
BAS_RANDOM      = 0x7298				; BASIC random number generator. 8 bytes on PC-1350
BASIC_PRINT_BUF = 0x6d00				; BASIC print and SIO buffer, 256 bytes
BASIC_STDVAR_Z  = 0x6c30				; BASIC std var Z
.endif

.if __PC_1360__
BAS_RANDOM      = 0xfde0				; BASIC random number generator. 8 bytes on PC-1360
BAS_START_PTR   = 0xffd7				; Pointer to BASIC start, low byte. High byte is +1
RAM_START_PTR   = 0xfff6				; Pointer to RAM start, low byte. High byte is +1
BASIC_STDVAR_Z  = 0xf9d0				; BASIC std var Z
.endif

.if __PC_2500__
BAS_START_PTR   = 0x6d91				; Pointer to BASIC start, low byte. High byte is +1
BASIC_STDVAR_Z  = 0x6c50				; BASIC std var Z
.endif

BASIC_STDVAR_Y  = BASIC_STDVAR_Z + 8
BASIC_STDVAR_X  = BASIC_STDVAR_Y + 8
BASIC_STDVAR_W  = BASIC_STDVAR_X + 8
BASIC_STDVAR_V  = BASIC_STDVAR_W + 8
BASIC_STDVAR_U  = BASIC_STDVAR_V + 8
BASIC_STDVAR_T  = BASIC_STDVAR_U + 8

	;; -----------------------------------------------
	;; This macro is used to write to the internal
	;; RAM of a PC-1350 when the ML program is
	;; running on a RAM card. When not used, a
	;; simple STD would show the following behaviour:
	;;  o F1 = 0: 'value is written to 0x6...
	;;      and 0x2... (image)
	;;  o F1 = 1: value NOT written to 0x6...
	;;      but only to 0x2... (image)
	;; Executing STD when the ML program runs in
	;; internal RAM or internal ROM works as expected
	;; 1 or 2 bytes
	;; -----------------------------------------------
.if __PC_1350__
.macro STD_HIMEM
	CAL 0x1d99					; STD, RTN found in ROM listing
.endm
.else
.macro STD_HIMEM
	STD
.endm
.endif

	;; -----------------------------------------------
	;; Move BA minus one to X and DP
	;; 2 or 5 bytes
	;; -----------------------------------------------
.if __PC_1350__
.macro MV_BA_MINUS_1_TO_X
	CAL 0x0297					; INT_ROM_mvBAminus1_X
.endm
.else
.if __PC_2500__
.macro MV_BA_MINUS_1_TO_X
	CAL 0x02bd					; INT_ROM_mvBAminus1_X
.endm
.else
.macro MV_BA_MINUS_1_TO_X
	LP REG_XL
	LIQ REG_A
	MVB
	DX
.endm
.endif
.endif

	;; -----------------------------------------------
	;; Move BA minus one to Y and DP
	;; 2 or 5 bytes
	;; -----------------------------------------------
.if __PC_1350__
.macro MV_BA_MINUS_1_TO_Y
	CAL 0x02b5					; INT_ROM_mvBAminus1_Y
.endm
.else
.if __PC_2500__
.macro MV_BA_MINUS_1_TO_Y
	CAL 0x02db					; INT_ROM_mvBAminus1_Y
.endm
.else
.macro MV_BA_MINUS_1_TO_Y
	LP REG_YL
	LIQ REG_A
	MVB
	DY
.endm
.endif
.endif

.endif

