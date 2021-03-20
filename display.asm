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
	;; file     : display.asm
	;; author   : puehringer edgar
	;; date     : 24.04.2020
	;; assembler: as61860
	;; -----------------------------------------------

.area chip8 (REL)

.include "basic.h"
.include "display.h"

.if __PC_1350__
DISPLAY_BITBLT_COPY = BASIC_PRINT_BUF
DISPLAY_CLR_VRAM_COPY = BASIC_PRINT_BUF+(display_clr_vram_impl-display_bitblt)
.endif

    ;; -----------------------------------------------
	;; For reasons I don't know display_bitblt does
	;; not run reliable (draws random patterns)
	;; when located on the memory card on a PC-1350.
	;; So we copy display_bitblt and some other code
	;; to a location outside the memory card (print
	;; buffer). display_init must be called before the
	;; first call of any other display function. Only
	;; necessary when using the PC-1350.
    ;; -----------------------------------------------
display_init::
.if __PC_1350__
	LP REG_XH
	LIA >(display_bitblt-1)
	EXAM
	LP REG_XL
	LIA <(display_bitblt-1)
	EXAM
	LP REG_YH
	LIA >(DISPLAY_BITBLT_COPY-1)
	EXAM
	LP REG_YL
	LIA <(DISPLAY_BITBLT_COPY-1)
	EXAM
	LIA (display_clr_vram_end-display_bitblt-1)
	PUSH
lc0101:
	IXL
	IY
	STD_HIMEM
	LOOP lc0101
.endif
	RTN

	;; -----------------------------------------------
    ;; Cycles: See summary at end of function
	;; XORs a block of 24 bytes from internal RAM at
    ;; REG_WBCD .. REG_WBCD+23 to the display RAM.
	;; Zero flag is set if there are no "collisions"
	;; Input A (cur. y, 0..1),
	;;       B (graph. cur. x, 0..149)
	;; Return N (Number of non zero bytes)
	;; Used Registers: I,A,B,K,L,M,N,Y,DP,C,Z
	;; -----------------------------------------------
display_bitblt:
	LP REG_K					; 2
	EXAM						; 3		; A --> K (cur. Y)
	EXAB						; 5
	PUSH						; 3		; Push graph. X cursor
	PUSH						; 3		; Push dummy for Yl upper limit
	RA							; 4
	LP REG_M					; 2
	EXAM						; 3		; 0 --> REG_M. will remember collisions
	LDM							; 2		; A=0 again
	LP REG_N					; 2
	EXAM						; 3		; 0 --> REG_N. will count non-zero bytes
	LIA REG_WBCD				; 4
	LP REG_L					; 2
	EXAM						; 3		; Reg. L will cycle through REG_WBCD .. REG_WBCD+23
	;; =================================
	                            ; 41 Cycles

lc0601:
	TSIM 0x07					; 4			; Procondition: P should point to reg. L
	JRNZP lc0602				; 7 4
	LP REG_K					;   2
	LDM							;   2
	EXAB						;   5		; K --> B (cur. Y)
	POP							;   2		; Fetch Yl upper limit
	POP							;   2
	PUSH						;   3		; Graph. X cursor --> A
	CALL display_addr			;   8+120	; Y is now display address-1
	PUSH						;   3		; Push Yl upper limit
	INCK						; 	4
	;; =================================
								; 148 extra cycles for address calculation (3 times) 
lc0602:
	IY							; 6
	LP REG_L					; 2
	LDM							; 2
	STP							; 2		; L --> P
	LDM							; 2		; REG_YZWBCD[L] --> A
	CPIA 0						; 4
	JRZP lc0605					; 7 4	; If byte is 0, skip the whole output process
	EXAB						;   5	; B = (P)

; Check if display block has to be changed
	POP							;   2
	PUSH						;   3	; Yl upper limit --> A
	LP REG_YL					;   2
	CPMA						;   3 
	JRCP lc0603_w				;   7 4	; If Yl < limit, jump ahead
	SBIM VRAM_BLK_SIZE-1		;     4	; Decrease Yl by video RAM block size
	LP REG_YH					;     2
	ADIM >(VRAM_L1C2-VRAM_L1C1) ;     4	; Increase Yh by video RAM block delta, high byte
	DY							;     6
lc0603:							;  (13)
	LDD							;   3	; A = (DP)
	EXAB						;   5	; A = (P), B = (DP)
	XOMA REG_B					;   56	; B = B XOR A
	EXAM						;   3	; LP is set to REG_B in macro
	STD							;   2
	EXAM						;   3	; A = pattern from int. RAM, B = pattern on display
	ANMA						;   3	; Mask pattern on display with pattern from int. RAM
	SBM							;   3
	EXAM						;   3	; A = delta. If <> 0, collision detected
	LP REG_M					;   2
	ORMA						;   3	; Remember collisions on reg. M
	INCN						;   4	; Inc. N (number of non-zero bytes)
	;; =================================
								; 122 extra cycles for each no zero byte 
lc0605:
	INCL						; 4
	LP REG_L					; 2
	CPIM REG_WBCD+24			; 4
	JRCM lc0601					; 7		; Loop through REG_WBCD .. REG_WBCD+23
	;; =================================
								; 24*53-3+3*148 (addr. calc) = 1713 cycles, plus 126 for each non-zero

;	LIJ 1						; 4
	POP							; 2		; Fetch Yl upper limit
	POP							; 2		; Fetch graph. X cursor
	LP REG_M					; 2
	CPIM 0						; 4		; Set zero flag if reg. M is 0
	RTN							; 4
	;; =================================
	                            ; 18 cycles

	;; Intro					  41 cycles
	;; Main loop				1713 cycles
	;; Outro					  18 cycles
	;; =================================
	;; All white                1772 cycles, plus 122 for each non-zero byte
	;; Single bit sprite        1894 cycles ( 7,40 ms) ~  4 timer ticks
	;; 15 non-zero bytes        3602 cycles (14,07 ms) ~  7 timer ticks
	;;  8 non-zero bytes        2748 cycles (10,73 ms) ~  5 timer ticks
	;; 24 non-zero bytes        4700 cycles (18,36 ms) ~  9 timer ticks
	;; =================================
; Wait code collected here
lc0603_w:
	WAIT 0						; 6		; For constant runtime
	JRM lc0603					; 7

display_clr_vram_impl:
	FILD						; 4+d*3
	LIDL <VRAM_L2C1				; 5
	FILD						; 4+d*3
	RA							; 4
	CALL display_callback       ; 8+10
	RA							; 4
	LIDL <VRAM_L3C1				; 5
	FILD						; 4+d*3
	LIDL <VRAM_L4C1				; 5
	FILD						; 4+d*3
	RTN                         ; 4
	;; =================================
	                            ; 71+d*12 Cycles

display_clr_vram_end:

    ;; -----------------------------------------------
    ;; Cycles: 411 = 1,61 ms
	;; Deletes a block of 30 display rows
	;; Input value: DP (address of display RAM)
	;; Used Registers: A,I,DP + regs in callback
	;; -----------------------------------------------
display_clr_vram::
	LII  30-1					; 4		; write 30 bytes with FILD

	;; -----------------------------------------------
    ;; Cycles: 71+d*12, d=I-1, max. 407
	;; Like display_clr_vram, but clears only
	;; I-1 graphic rows
	;; Input value: DP, I (number of graphic rows - 1)
	;; Used Registers: A,I,DP + regs in callback
	;; -----------------------------------------------
display_clr_vram_part::
	RA							; 4
.if __PC_1350__
	JP DISPLAY_CLR_VRAM_COPY	; 6
.else
	JP display_clr_vram_impl	; 6
.endif
	;; =================================
	;; display_clr_vram_impl	; 61+d*12
	;; =================================
	                            ; 71+d*12 Cycles

	;; -----------------------------------------------
	;; Cycles: 120 for X=0 .. 89, 125 for X=90 .. 119,
	;; 121 for X=120 .. 149
	;; Calculates the displayaddress of a given
    ;; graphics cursor location.
	;; Input A (graph. cur. x, 0..149),
	;;       B (cur. y, 0..3)
	;; Return val: Y (display address-1)
	;;             A (value of Yl, where Y should
	;;               change to the next display block)
	;; Used Registers: I,A,B,Y,P,C,Z
	;; -----------------------------------------------
display_addr::
	PUSH						; 3		; Push graph. X cursor

; First we handle the column block address
	CPIA  60					; 4		; If not 0 .. 59, jump ahead
	JRNCP lc0402				; 4 7
	NOPT						; 3		; For constant runtime

	CPIA 30						; 4		; If not 0 .. 29, jump ahead
	JRNCP lc0401				; 4 7
	NOPT						; 3		; For constant runtime

	LIA >VRAM_L1C1				; 4		; 0 .. 29
	LII 0						; 4
	JRP lc0405					; 7		; "break", 37 cycles till here

lc0401:
	LIA >VRAM_L1C2				; 4		; 30 .. 59
	LII 30						; 4
	JRP lc0405					; 7		; "break", 37 cycles till here

lc0402:
	CPIA 90						; 4		; If 60 .. 89, jump ahead
	JRCP lc0403					; 4 7

	CPIA 120					; 4		; If not 90 .. 119, jump ahead
	JRNCP lc0404				; 4 7

	LIA >VRAM_L1C4				; 4		; 90 .. 119
	LII 90						; 4
	JRP lc0405					; 7		; "break", 42 cycles till here

lc0403:
	LIA >VRAM_L1C3				; 4		; 60 .. 89
	LII 60						; 4
	JRP lc0405					; 7		; "break", 37 cycles till here

lc0404:
	LIA >VRAM_L1C5				; 4		; 120 .. 149
	LII 120						; 4; 	; 38 cycles till here

lc0405:
	LP REG_YH					; 2		; Write result to YH
    EXAM						; 3
	POP							; 2		; Graph. X cursor --> A
	;; =================================
	                        	; 44 Cycles for 0 .. 89, 49 for 90 .. 119, 45 for 120 .. 149

; Now we handle the row
	EXAB						; 5		; 000000Xx, Graph. X cursor --> B
	RC							; 2		; 000000Xx 0
	SR							; 2		; 0000000X x
	SR							; 2		; x0000000 X
	JRNCP lc0406				; 7 4
	ORIA 0x3c					;   4	; x0XXXX00 X
	JP lc0407					;   6
lc0406:
	WAIT 1						; 7		; For constant runtime
lc0407:
	RC							; 2		; x0XXXX00 0
	SR							; 2		; 0x0XXXX0 0
	LP REG_YL					; 2
	EXAM						; 3
	;; =================================
	                            ; 78 Cycles for 0 .. 89, 83 for 90 .. 119, 79 for 120 .. 149

; Calc value of Yl, where Y should change to the next display block
	LDM							; 2		; row start address low byte --> A
	ADIA VRAM_BLK_SIZE			; 4
	PUSH						; 3		; Push value of Yl, where Y should change to next

; Calc low byte of display address
	EXAB						; 5		; Graph. X cursor --> A
	LP   REG_I					; 2
	EXAM						; 3		; Block offset --> A, Graph. X cursor --> I
	SBM							; 3		; Pos. in block --> I
	EXAM						; 3		; Pos. in block --> A 
	LP REG_YL					; 2
	ADM							; 3		; Add pos. in block to YL

	DY							; 6		; Y is now display address-1
	POP							; 2		; Value of Yl, where Y should change to next --> A
	RTN							; 4
	;; =================================
	                            ; 120 Cycles for 0 .. 89, 125 for 90 .. 119, 121 for 120 .. 149

	;; -----------------------------------------------
    ;; Cycles: See summary at end of function
	;; Copy a chip8 style bit pattern (max. 24 byte)
    ;; to the internal RAM at position WBCD. In this
    ;; process the bit pattern is turned 90 degrees.
    ;; If A is > 0, some leading empty lines will be
	;; included
	;; Input X (location of sprite to draw-1)
	;;       A (number of bytes to rotate, 0..24-B)
	;;       B (number of leading empty lines, 0..23)
	;;       K (Screen bound bitmask, 0xff for no
	;;          clipping)
	;; Return N (number of bytes rotated)
	;; Used Registers: I,A,B,L,N,X,DP,WBCD,C,Z
	;; -----------------------------------------------
display_c8rotate:
	DECA						; 4		; A=num rot-1, B leading
	JRCP lc0510					; 4 7	; If number of bytes to rotate == 0, jump to end
	PUSH						; 3		; Push number of bytes to rotate
	RA							; 4
	LP REG_WBCD					; 2
	LII 23						; 4
	FILM						; 28	; WBCD .. WBCD+23 = 0
	LIA REG_WBCD+7				; 4		; A=WBCD+7 (end of first 8 byte block)
	LP REG_L					; 2
	EXAM						; 3		; B=leading, L=WBCD+7
	POP							; 2		; Fetch number of bytes to rotate from stack
	LP REG_I					; 2		; 
	EXAM						; 3		; B=leading, I=num rot-1, L=WBCD+7
	EXAB						; 5		; A=leading, I=num rot-1, L=WBCD+7
	CPIA 24						; 4
	JRNCP lc0510				; 4 7	; If number of leading lines >= 24, jump to end
; Check if leading lines + number of bytes to rotate > 24
	PUSH						; 3		; Push number of leading empty lines to stack
	LP REG_I					; 2
	EXAM						; 3		; A=num rot-1, I=leading, L=WBCD+7
	ADM							; 3		; A=num rot-1, I=I+A=leading+rot-1, L=WBCD+7
	EXAM						; 3		; A=leading+rot-1, I=num rot-1, L=WBCD+7
	CPIA 24						; 4
	JRCP lc0501_w				; 7 4	
	LII 23						;   4	; A=leading+rot-1, I=23 L=WBCD+7
	POP							;   2	; A=leading, I=23, L=WBCD+7
	PUSH						;   3
	SBM							;   3   ; A=leading, I=23-leading=number of bytes to rotate-1, L=WBCD+7
lc0501:							;(9)
	LDM							; 2		; A=num rot-1, I=num. rot-1, L=WBCD+7
	LP REG_N					; 2
	EXAM						; 3		; I=num rot-1, L=WBCD+7, N=num. rot-1
	INCN						; 4		; I=num rot-1, L=WBCD+7, N=num. rot.
	POP							; 3		; Fetch number of leading empty lines from stack
										; A=leading, I=num rot-1, L=WBCD+7
	LP REG_L					; 2
	CPIA 16						; 4

	JRCP lc0503					; 7 4	; If number of leading lines< 16, jump ahead
	SBIA 16						;   4	; A = A - 16
	ADIM 16						;   4	; L = L + 16
	WAIT 4						;   10	; For constant runtime
	JRP lc0505					;   7
lc0503:
	CPIA 8						; 4
	JRCP lc0504					; 7 4	; If number of leading lines< 8, jump ahead
	SBIA 8						;   4	; A = A - 8
	ADIM 8						;   4	; L = L + 8
	JP lc0505					;   6
lc0504:
	WAIT 5						;   11	; For constant runtime
lc0505:
	TO_BITMASK					; 42	; A=output bmask, I=num rot-1, L=WBCD+7 (+0, 8 or 16)
	;; =================================
	                            ; 203 Cycles
lc0506:
	EXAB						; 5		; B = Output bit mask
	LIA 7						; 4
	PUSH						; 3		; Loop 8 times
	IXL							; 7		; X++, A = (X)
	LP REG_K					; 2
	EXAM						; 3
	ANMA						; 3
	EXAM						; 3		; A = A & K (Apply screen bound bitmask)
	PUSH						; 3		; Push A & K to stack
	LP REG_L					; 2
	LDM							; 2
	STP							; 2		; L --> P
	POP							; 2		; Fetch A & K from stack
	;; =================================
	                            ; 41 Cycles
lc0507:
	SR							; 2		; Shift the byte from (X) out to C
	JRNCP lc0508				; 7 4
	EXAB						;   5	; A = Output bit mask, B = Shifted (X)
	ORMA						;   3	; (P) |= Output bit mask
	EXAB						;   5	; A = Shifted (X), B = Output bit mask
lc0508:
	DECP						; 2		; P--
	LOOP lc0507					; 10 7
	;; =================================
	                            ; 8*21-3= 165 Cycles, 10 extra for each black Pixel

	EXAB						; 5		; A = Output bit mask, B = Shifted (X)
	RC							; 2
	SL							; 2		; Shift output bit mask left
	LP REG_L					; 2
	JRNCP lc0509				; 7 4
	SL							;   2	; Shift output bit mask in again from the right
	ADIM 8						;   4	; L = L + 8
	DECI						;   4	; I--
	JRNCM lc0506				;   7	; Loop is over when number of bytes to rotate < 0
	;; =================================
	                            ; 32 Cycles
	RTN							; 4

lc0509:
	NOPT						; 3		; For constant runtime
	DECI						; 4		; I--
	JRNCM lc0506				; 7		; Loop is over when number of bytes to rotate < 0
	;; =================================
	                            ; 32 Cycles (alternative exit, same cycles)
	RTN							; 4

	;; =================================
	;; Intro					 203 Cycles
	;; Main loop			 n*238-3 Cycles, n*(41+165+32)-3, 10 extra for each black pixel
	;; Outro					  32 Cycles
	;; =================================
	;;                     232+n*238 Cycles, 10 extra for each black pixel
	;; Single bit sprite         480 Cycles ( 1,88 ms) ~  1 timer tick
	;; Single black byte sprite  550 Cycles ( 2,15 ms) -  1 timer tick
	;; 15 black byte sprite     5002 Cycles (19,54 ms) ~ 10 timer ticks
	;; 15 byte w. 4 bit black   4402 Cycles (17,20 ms) ~  9 timer ticks
	;;  8 byte w. 4 bit black   2456 Cycles ( 9,59 ms) ~  5 timer ticks
	;; =================================

lc0510:
	RA							; 4
	LP REG_N					; 2
	EXAM						; 3		; N=0 (number of bytes rotated)
	RTN							; 4

; Wait code collected here
lc0501_w:
	NOPW						; 2		; For constant runtime
	JRM lc0501					; 7

	;; -----------------------------------------------
    ;; Cycles: 
	;; XORs a chip8 style sprite to the display RAM
	;; Input Position must be stored in the grapixs
	;;       cursor mem. loc. display_gcur_x/y
	;;       X (Location of sprite to draw-1)
	;;       A (Number of bytes)
	;; Return A (Number of non zero bytes handled by
	;;           the display_bitblt function)
	;;        Z (set if there are no "collisions")
	;; Used Registers: I,A,B,K,L,M,N,X,Y,P,DP,WBCD,C,Z
	;; -----------------------------------------------
display_c8draw::
	PUSH						; 3		; Number of bytes to draw to stack
	RA							; 4
	LP REG_M					; 2
	EXAM						; 3		; M = 0 (cur. Y)								
	LIDP display_gcur_y			; 8
	LDD							; 3		; Load graph. cursor Y
	CPIA 8						; 4
	JRCP lc0701					; 7 4	; If number of leading lines< 8, jump ahead
	SBIA 8						;   4	; A = A - 8	
	INCM						;   4	; M = 1 (cur. Y)
lc0701:
	EXAB						; 5		; B = Number of leading empty lines
	LIDP display_maxgcur_x		; 8
	LDD							; 3		; Load Max. graph. cursor X
	LP REG_I					; 2
	EXAM						; 3		; I = Max. graph. cursor X
	LIDP display_gcur_x			; 8
	LDD							; 3		; Load graph. cursor X
	CPMA						; 3
	JRCP lc0706					; 4 7	; If graph. cur. X > max. graph. cur. X, jump to end
	SBIM 7						; 4
	CPMA						; 3
	JRNCP lc0704				; 7 4	; If nothing has to be clipped, jump ahead
	EXAM						;   3	; A = Max. graph. cur. X, I = Graph. cur. X
	SBM							;   3	; I = Number of bytes to clip, 1..7
	DECI						;   4   ; 1..7 --> 0..6
	LDM							;   2
	ANIA 0x03					;   4	; 4..6 --> 0..2
	PUSH						;	3	; Loop 1..3 times
	LIA 0xff					;   4
lc0702:
	SL							;   2	; 0xfe, 0xfc or 0xf8. C is null because of DECI
	LOOP lc0702					;  10 7
	TSIM 0x04					;   4	; Non-zero if I = 4..6
	JRZP lc0703					;   7 4
	ANIA 0x0f					;     4
	SWP							;     2
lc0703:
	JP lc0705					;   6
lc0704:
	LIA 0xff					; 4
lc0705:
	LP REG_K					; 2
	EXAM						; 3
	POP							; 2		; Fetch number of bytes to draw from stack
	;; =================================
	                            ; 176 cycles max. till here

	;; Input X (location of sprite to draw-1)
	;;       A (number of bytes to rotate, 0..24-B)
	;;       B (number of leading empty lines, 0..23)
	;;       K (Screen bound bitmask, 0xff for no
	;;          clipping)
	;; Return N (number of bytes rotated)
	CALL display_c8rotate		
	LP REG_N					; 2
	EXAM						; 3		; A=number of bytes rotated
;	ADIA 1 						; 4		; If we have at least 1 byte, one will stay after SR 
	SR							; 2		; 2 bytes = aprox. 1 tick
    CALL display_callback		; 8+10	; Plus payload
	;; Intro					 176 cycles max.
	;; display_c8rotate		480-5002 cycles
	;; Outro					  29 cycles
	;; =================================
	;;                      685-5207 cycles

	LIDP display_gcur_x			; 8
	LDD							; 3		; Load graph. cursor X
	EXAB						; 5
	LP REG_M					; 2
	EXAM						; 3		; A = M (cur. Y)
	;; Input A (cur. y, 0..1),
	;;       B (graph. cur. x, 0..149)
	;; Return N (Number of non zero bytes)
.if __PC_1350__
	CALL DISPLAY_BITBLT_COPY
.else
	CALL display_bitblt
.endif
	LP REG_N					; 2
	EXAM						; 3		; A = N (Number of non zero bytes handled)
	RTN							; 4
	;; Intro					  21 cycles
	;; display_bitblt      1894-3602 cycles
	;; Outro					   9 cycles
	;; =================================
	;;                     1924-3602 cycles
	;; =================================
	;; Total               2609-8809 cycles (7,52-34,41 ms, 133-29 sprites/sec)

lc0706:
	POP							; 2		; Fetch number of bytes to draw from stack
	RA							; 4		; Number of non zero bytes handled is 0
	RC							; 2		; Sets also Z
	RTN							; 4

	;; -----------------------------------------------
	;; This is a dummy callback function. The jump
    ;; address at display_callback+1 may be
	;; overwritten using a macro in display.h
	;; Input A (Number of missed timer ticks)
	;; -----------------------------------------------
display_callback::
	JP lc0801                   ; 6
lc0801:
	RTN                         ; 4

display_gcur_x::
	.db 0x00
display_gcur_y::
	.db 0x00
display_maxgcur_x::
	.db VRAM_BLK_SIZE*VRAM_BLK_CNT-1

