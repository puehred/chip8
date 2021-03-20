	;;***************************************************************************
	;;*                                                                         *
	;;*   This program is free software; you can redistribute it and/or modify  *
	;;*   it under the terms of the GNU General Public License as published by  *
	;;*   the Free Software Foundation; either version 2 of the License, or     *
	;;*   (at your option) any later version.                                   *
	;;*                                                                         *
	;;***************************************************************************

	;; -----------------------------------------------
	;; Display related funtions for chip-8
	;; file     : display.h
	;; author   : puehringer edgar
	;; date     : 25.04.2020
	;; assembler: as61860
	;; -----------------------------------------------

.ifndef display_h
.define display_h

.include "target.h"
.include "regs.h"

.if __PC_1360__

VRAM_L1C1  = 0x2800;	 10240			; Display RAM adresses
VRAM_L1C2  = 0x2a00;	 10752			; LnCm = Line n Column m (one column is 30 pixels wide here)
VRAM_L1C3  = 0x2c00;	 11264
VRAM_L1C4  = 0x2e00;	 11776
VRAM_L1C5  = 0x3000;	 12288
VRAM_L2C1  = 0x2840;	 10304
VRAM_L2C2  = 0x2a40;	 10816
VRAM_L2C3  = 0x2c40;	 11328
VRAM_L2C4  = 0x2e40;	 11840
VRAM_L2C5  = 0x3040;	 12352
VRAM_L3C1  = 0x281e;	 10270
VRAM_L3C2  = 0x2a1e;	 10782
VRAM_L3C3  = 0x2c1e;	 11294
VRAM_L3C4  = 0x2e1e;  	 11806
VRAM_L3C5  = 0x301e;	 12318
VRAM_L4C1  = 0x285e;	 10334
VRAM_L4C2  = 0x2a5e;	 10846
VRAM_L4C3  = 0x2c5e;	 11358
VRAM_L4C4  = 0x2e5e;	 11870
VRAM_L4C5  = 0x305e;	 12382

.else

VRAM_L1C1  = 0x7000;	 28672			; Display RAM adresses
VRAM_L1C2  = 0x7200;	 29184			; LnCm = Line n Column m (one column is 30 pixels wide here)
VRAM_L1C3  = 0x7400;	 29696
VRAM_L1C4  = 0x7600;	 30208
VRAM_L1C5  = 0x7800;	 30720
VRAM_L2C1  = 0x7040;	 28736
VRAM_L2C2  = 0x7240;	 29248
VRAM_L2C3  = 0x7440;	 29760
VRAM_L2C4  = 0x7640;	 30272
VRAM_L2C5  = 0x7840;	 30784
VRAM_L3C1  = 0x701e;	 28702
VRAM_L3C2  = 0x721e;	 29214
VRAM_L3C3  = 0x741e;	 29726
VRAM_L3C4  = 0x761e;  	 30238
VRAM_L3C5  = 0x781e;	 30750
VRAM_L4C1  = 0x705e;	 28766
VRAM_L4C2  = 0x725e;	 29278
VRAM_L4C3  = 0x745e;	 29790
VRAM_L4C4  = 0x765e;	 30302
VRAM_L4C5  = 0x785e;	 30814

.endif

VRAM_BLK_SIZE = 30						; Size of one display memory block
VRAM_BLK_CNT  = 5						; Number of display memory blocks

.globl display_init
.globl display_clr_vram
.globl display_clr_vram_part
.globl display_c8draw
.globl display_addr
.globl display_callback
.globl display_gcur_x
.globl display_gcur_y
.globl display_maxgcur_x

	;; -----------------------------------------------
	;; Sets the max. graph. cursor X position for
	;; display_c8bitblt. Pixels right of this position
	;; will be invisible.
	;; Input A (max. graph. cursor X position, 1..149)
	;; Used registers and flags: DP
	;; 4 bytes, Cycles: 10
	;; -------------------------; Cycles -------------
.macro SET_MAX_GCUR_X
	LIDP display_maxgcur_x		; 8
	STD							; 2
.endm

	;; -----------------------------------------------
	;; Modifies the jump address in the dummy
	;; callback function to define a customized
	;; callback function. This may be used to update
	;; timer counters etc. while long running display
	;; functions. The callback function gets an
	;; input A, which is the number of missed timer
	;; on very long running display functions or
	;; 0 if it should cause a regular timer check
	;; -----------------------------------------------
.macro SET_DISP_CALLBACK arg_addr
	LIA >(arg_addr)
	LIDP display_callback+1
	STD
	LIA <(arg_addr)
	LIDP display_callback+2
	STD
.endm

	;; -----------------------------------------------
	;; Turns the display on
	;; 6 bytes, Cycles: 13
	;; -------------------------; Cycles -------------
.macro DISP_ON
	LIA 0x01					; 4
	LIP PORT_C					; 4
	EXAM						; 3
	OUTC						; 2
.endm

	;; -----------------------------------------------
	;; Turns the display off
	;; 5 bytes, Cycles: 13
	;; -------------------------; Cycles -------------
.macro DISP_OFF
	RA							; 4
	LIP PORT_C					; 4
	EXAM						; 3
	OUTC						; 2
.endm

.endif
