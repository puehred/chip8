	;;***************************************************************************
	;;*                                                                         *
	;;*   This program is free software; you can redistribute it and/or modify  *
	;;*   it under the terms of the GNU General Public License as published by  *
	;;*   the Free Software Foundation; either version 2 of the License, or     *
	;;*   (at your option) any later version.                                   *
	;;*                                                                         *
	;;***************************************************************************

	;; ----------------------------------------------- -*- asm -*-
	;; Sound output related funtions for chip-8
	;; file     : sound.h
	;; author   : puehringer edgar
	;; date     : 25.04.2020
	;; assembler: as61860
	;; -----------------------------------------------

.ifndef sound_h
.define sound_h

; port C bits:
; |     | BZ3 | BZ2 | BZ1 | OFF | HLT |  CL | DIS |
;    7     6     5     4     3     2     1     0
;
; Buzzer bits:
;
; BZ3  BZ2  BZ1  Xout         Xin
; ======================================
;  0    0    0   LOW          Not Active
;  0    0    1   HIGH         Not Active
;  0    1    0   2kHz         Not Active
;  0    1    1   4kHz         Not Active
;  1    0    0   LOW          Active
;  1    0    1   HIGH         Active
;  1    1    x   Xin -> Xout  Active

;; ---------------------------------------------------
;; Sets the Xin/Xout ports to silence 
;; Used registers and flags: P,Z
;; 5 bytes, 10 cycles
;; -----------------------------; Cycles -------------
.macro	SND_OFF
		LIP  PORT_C				; 4
		ANIM 0x8F				; 4		; 10001111
		OUTC					; 2
.endm

;; ---------------------------------------------------
;; Sets the Xout port to 2 kHz
;; Used registers and flags: P,Z
;; 7 bytes, 14 cycles
;; -----------------------------; Cycles -------------
.macro	SND_2KHZ
		LIP  PORT_C				; 4
		ANIM 0x8F				; 4		; 10001111
		ORIM 0x20				; 4		; 00100000
		OUTC					; 2
.endm

;; ---------------------------------------------------
;; Sets the Xout port to 4 kHz
;; Used registers and flags: P,Z
;; 7 bytes, 14 cycles
;; -----------------------------; Cycles -------------
.macro	SND_4KHZ
		LIP  PORT_C				; 4
		ANIM 0x8F				; 4		; 10001111
		ORIM 0x30				; 4		; 00110000
		OUTC					; 2
.endm

;; ---------------------------------------------------
;; Sets the Xout port to 2 kHz (A=0x20),
;; 4 kHz (A=0x30) or silence (A=0) depending on reg. A
;; Used registers and flags: A,P,Z
;; 8 bytes, 17 cycles
;; -----------------------------; Cycles -------------
.macro	SND_REG_A
		ANIA 0x30				; 4		; prevent other bits from beeing modified
		LIP  PORT_C				; 4
		ANIM 0x8F				; 4		; 10001111
		ORMA					; 3		; 00xx0000
		OUTC					; 2
.endm

.endif

