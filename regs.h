	;;***************************************************************************
	;;*                                                                         *
	;;*   This program is free software; you can redistribute it and/or modify  *
	;;*   it under the terms of the GNU General Public License as published by  *
	;;*   the Free Software Foundation; either version 2 of the License, or     *
	;;*   (at your option) any later version.                                   *
	;;*                                                                         *
	;;***************************************************************************

	;; -----------------------------------------------
	;; registers, ports and common macros
	;; for sharp pocket computers with 61860 cpu
	;; file     : regs.h
	;; author   : puehringer edgar
	;; date     : 15.12.2015                 
	;; assembler: as61860                    
	;; -----------------------------------------------

.ifndef regs_h
.define regs_h

; CPU speed:
;
; one cycle is 3.906 usec on machines with 768 kHz resonators
; and 5.208 usec on machines with 576 kHz resonators
; The 2 msec timer has the zero flag set after 512 cycles with the 768 kHz resonator
; and 384 cycles with the 576 kHz resonator 

; CPU registers

REG_I	=    0x00               ; index register
REG_J	=    0x01               ; index register
REG_A	=    0x02               ; accumulator
REG_B	=    0x03               ; accumulator
REG_XL	=    0x04               ; LSB of adress pointer
REG_XH	=    0x05               ; MSB of adress pointer
REG_YL	=    0x06               ; LSB of adress pointer
REG_YH	=    0x07               ; MSB of adress pointer
REG_K	=    0x08               ; counter
REG_L	=    0x09               ; counter
REG_M	=    0x0A               ; counter
REG_N	=    0x0B               ; counter

; Ports

PORT_A  = 92                    ; 0x5c
PORT_B  = 93                    ; 0x5d
PORT_F  = 94                    ; 0x5e, sometimes called Port C
PORT_C  = 95                    ; 0x5f, sometimes called Port CR

; TEST mask

TEST_CNT_512     = 0x01         ; 512 ms counter
TEST_CNT_2       = 0x02         ; 2 ms counter
TEST_BRK         = 0x08         ; break key
TEST_RESET       = 0x40         ; hard reset
TEST_XIN         = 0x80         ; Xin port

; BCD pseudo registers
; used for BCD computation by ROM functions

REG_XBCD = 0x10
REG_YBCD = 0x18
REG_ZBCD = 0x20
REG_WBCD = 0x28

.macro ILLEGAL_INST
	.db 0x16					; Illegal CPU instruction - forces the emulator to dump internal RAM
.endm

	;; -----------------------------------------------
	;;      ; Shift left without carry
	;; -----------------------------------------------
.macro  SLNC
	RC                          ; 2
	SL                          ; 2
.endm

	;; -----------------------------------------------
	;;      ; Shift right without carry
	;; -----------------------------------------------
.macro  SRNC
	RC                          ; 2
	SR                          ; 2
.endm

	;; -----------------------------------------------
	;; Bitwise NOT of A. Uses J for intermediate
	;; values. J is set to 1 at the end
	;; Used registers and flags: A,J,P,C,Z
	;; 6 bytes, 16 cycles
	;; -------------------------; Cycles -------------
.macro	NOT
	LIJ  0xFF					; 4
	LP   REG_J					; 2
	SBM							; 3
	EXAM						; 3
	LIJ  0x01					; 4
.endm

	;; -----------------------------------------------
	;; XOR the contents of the address given as arg_p
	;; with the contents of the accumulator. Uses J
    ;; and one bytes on stack for intermediate values.
	;; J is set to 1 at the end
	;; Used registers and flags: A,J,P,C,Z
	;; 22 bytes, 56 cycles
	;; -------------------------; Cycles -------------
.macro	XOMA arg_p				;  			     A            (P)          J
	PUSH						; 3	    ;       e1 --> Stack
	LP arg_p					; 2
	EXAM						; 3		;       e2             e1
	ORMA						; 3		;       e2          e1|e2
	EXAM						; 3		;    e1|e2             e2
	LP   REG_J					; 2
	EXAM						; 3		;                      e2      e1|e2
	POP							; 2		;       e1             e2      e1|e2
	LP arg_p					; 2
	ANMA						; 3		;       e1          e1&e2      e1|e2
	LIA  0xFF					; 4		;     0xff          e1&e2      e1|e2
	EXAM						; 3		;    e1&e2           0xff      e1|e2
	SBM							; 3		;    e1&e2       /(e1&e2)      e1|e2
	EXAM						; 3		; /(e1&e2)          e1&e2      e1|e2
	LP   REG_J					; 2
	ANMA						; 3		; /(e1&e2)          e1&e2    (e1|e2)&/(e1&e2)=e1(+)e2
	EXAM						; 3		;  e1(+)e2          e1&e2   /(e1&e2)
	LP arg_p					; 2
	EXAM						; 3		;    e1&e2        e1(+)e2   /(e1&e2)
	LIJ  0x01					; 4		;    e1&e2        e1(+)e2       0x01
.endm

	;; -----------------------------------------------
	;; Maps a number 0..7 to a bit mask 
	;; 00000001..10000000. Uses J for intermediate
	;; values. J is set to 1 at the end
	;; Used registers and flags: A,J,P,C,Z
	;; 21 bytes, Cycles: 42 avg, 44 max
	;; -------------------------; Cycles -------------
.macro	TO_BITMASK
	LP   REG_J					; 2
	EXAM						; 3
	LDM							; 2
	ANIA 0x03					; 4		; 0..7 --> 0..3
	ADIA 1						; 4		; 0..3 --> 1..4
	CPIA 3						; 4
	.db 0x3a,0x04				; 7 4 	; JRCP lb1
	SL							;   2	; 3,4 --> 6,8
	ANIA 0xfc					;   4	; 6,8 --> 4,8
;lb1
	TSIM 0x04					; 4
    .db 0x38,0x02				; 7 4	; JRZP lb2
	SWP							;   2	; 1,2,4,8 --> 0x10,0x20,0x40,0x80
;lb2
	LIJ  0x01					; 4
.endm

.endif

