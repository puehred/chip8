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
.include "keyboard.h"

    ;; -----------------------------------------------
    ;; Cycles (no key pressed):
	;;   PC-1350: 1185 = 4,63 ms
	;;   PC-1360: 1256 = 4,91 ms
	;;   PC-2500: 1482 = 5,79 ms
    ;; One key pressed adds max. 149 cycles.
    ;; Keys pressed in more than one scan line
    ;; can even worsen the situation.
	;; -------------------------; Cycles -------------	
keyboard_raw_inkey::
	; Test break key
	LIA KEY_BREAK               ; 4		; A = KEY_BREAK
	TEST TEST_BRK               ; 4		; Test KON, which is wired to the break key
	JRNZP kb0106                ; 4		; If set, jump to SC and RTN

.if __PC_1350__ + __PC_1360__
	; Init for scan IA
	LP REG_K                    ; 2
	ANIM 0x00                   ; 4		; K = 0
	LP REG_L                    ; 2
	LIA 0x06                    ; 4
	EXAM                        ; 3		; L = 0x06  
	LP REG_M                    ; 2
	ORIM 0xff					; 4		; M = 0xFF
	LIB 0xff					; 4		; B = 0xFF
	LIP PORT_A                  ; 4
	LIA 0x01                    ; 4
	EXAM                        ; 3     ; (0x5c) = 0x01
	OUTA                        ; 3		; Port A = 0x01
	LIDP KEY_PORT				; 8		; (KEY port)
	LIA 0x00                    ; 4
.if __PC_1360__
	STD							; 2		; 0 --> KEY port
	WAIT 44						; 6+44
.else
	STD_HIMEM					; 13	; 0 --> KEY port
	WAIT 33						; 6+33
.endif
	;; =================================
	                            ; 115 Cycles
	; Scan IA
kb0101:
	LDM                         ; 2		; (0x5c) --> A, because P points still to 0x5c
	SLNC                        ; 4     ; Shift left without carry
	EXAM                        ; 3     ; Write shifted value back to (0x5c)
	INA                         ; 2     ; Port A --> A
	OUTA                        ; 3     ; Write shifted value back to port A
	PUSH						; 3
	RA							; 4
	CALL keyboard_callback      ; 8+10
	POP							; 2
	LP REG_M                    ; 2
	EXAM                        ; 3     ; M = A, A = M (0xff on first cycle)
	SLNC                        ; 4     ; Shift left without carry
	ANMA                        ; 3     ; Scan line masking
	EXAM                        ; 3     ; A is result from port A again, M fades away like 0xfe, 0xfc, 0xf8, 0xf0, 0xe0, 0xc0
	JRZP kb0102                 ; 7     ; If A == 0 (no key pressed), skip call in next line
	CALL kbcalcscan             ; (8+144-3)
kb0102:
	LP REG_L                    ; 2
	LDM                         ; 2     ; A = L
	LP REG_K                    ; 2
	ADM                         ; 3     ; K += A (L)
	DECL                        ; 4     ; L-- 
	LIP PORT_A                  ; 4
	JRNZM kb0101                ; 7     ; Stop looping after six times (IA1 .. IA6)
	;; =================================
	                            ; 87*6-3 (for last JR) = 519 Cycles

	; Init for scan key port
	ANIM 0x00                   ; 4     ; (0x5c) = 0x00
	OUTA                        ; 3		; Port A = 0x00
	LP REG_N                    ; 2
	LIA 0x01                    ; 4
	EXAM                        ; 3     ; N = 0x01
	LP REG_L                    ; 2
	LIA SCANLINES_KB            ; 4
	EXAM                        ; 3     ; L = 6 (PC-1350) or 7 (PC-1360)
	;; =================================
	                            ; 25 Cycles
	; Scan key port
kb0103:
	LP REG_N                    ; 2
	LDM                         ; 2     ; A = N
	STD_HIMEM                   ; 13/2	; A --> KEY port
.if __PC_1360__
	ADIM 1						; 4     ; N++
	WAIT 18						; 6+18
.else
	ANIA 0x1f                   ; 4
	ADM                         ; 3     ; if N < 0x20, N *= 2
	WAIT 4						; 6+4
.endif
	RA							; 4
	CALL keyboard_callback      ; 8+10
	INA                         ; 2     ; Port A --> A 
	JRZP kb0104                 ; 7     ; If A == 0 (no key pressed), skip call in next line
	CALL kbcalcscan             ; (8+144-3)
kb0104:
	LP REG_K                    ; 2
	ADIM 0x07                   ; 4     ; K += 7
	DECL                        ; 4     ; L--
	JRNZM kb0103                ; 7     ; Stop looping after six times (K01 .. K06)
	;; =================================
					; PC-1350:   82*6-3 (for last JR) = 489 Cycles
					; PC-1360:   82*7-3 (for last JR) = 571 Cycles

	LIA 0x00                    ; 4
	STD_HIMEM					; 13/2	; 0 --> KEY port
	EXAB                        ; 5
	CPIA KEY_MULTIPLE+1			; 4
	JRNCP kb0107                ; 7     ; Set carry if A < 0x41
.endif

.if __PC_2500__
	; Init for scan key port
	LP REG_K					; 2
	ANIM 0 						; 4		; K = 0
	LIB 0xff					; 4		; B = 0xff
	LIP PORT_A					; 4
	ANIM 0						; 4
	OUTA						; 3		; Port A = 0
	LIDP KEY_PORT_2				; 8
	ANID 0						; 6		; Key port 2 = 0
	LIDP KEY_PORT_1				; 8		; P = Key port 1, next STD writes to key port 1
	LP REG_N					; 2
	LIA 1						; 4
	EXAM 						; 3		; N = 1
	LP REG_L					; 2
	LIA 0x08					; 4
	EXAM						; 3		; L = 8
	;; =================================
	                            ; 73 Cycles

	; Scan key port
kb0101:									; K = 0, 7 .. 49, L = 8 .. 1, N = 1,2,4,8,16,2,4,8 
	LP REG_N					; 2
	CPIM 0x10					; 4
	JRCP kb0102					; 7 4	; If N >= 0x10, switch to key port 2

	RA							;   4
	STD							;   2	; Key port 1 = 0
	LIDP KEY_PORT_2				;   8	; Key port 2
	INCA						;   4
	EXAM						;   3	; N = 1

kb0102:
	LDM							; 2		; A = N = 1,2,4,8,1,2,4,8
	STD							; 2		; Key port 1 = A (= N) 
	ADM			 				; 3		; N *= 2
	WAIT 15						; 6+15
	RA							; 4
	CALL keyboard_callback      ; 8+10
	INA			 				; 2		; A = Port A
	ANIA 0x7f					; 4
	JRZP kb0103					; 7		; If no key pressed, continue
	CALL kbcalcscan				; (8+144-3)
kb0103:
	LP REG_K					; 2
	ADIM 0x07					; 4		; K += 7
	DECL 						; 4		; L--
	JRNZM kb0101				; 7		; Loop while L > 0 (8 times)
	;; =================================
	                            ; 93*8-3 (for last JR) = 741 Cycles

	; Init for scan IA
	RA							; 4
	STD							; 2		; Key port 2 = 0
	LP REG_L					; 2
	LIA 0x06					; 4
	EXAM 						; 3		; L = 6
	LP REG_M					; 2
	ORIM 0xff					; 4		; M = 0xff
	LIP PORT_A					; 4
	LIA 1						; 4
	EXAM						; 3
	OUTA 						; 3		; Port A = 1
	WAIT 33						; 6+33
	;; =================================
	                            ; 74 Cycles

	; Scan IA
kb0104:
	LDM							; 2		; A = (0x5c)
	SLNC                        ; 4     ; Shift left without carry
	EXAM						; 3
	INA							; 2		; A = Port A 
	OUTA						; 3		; Port A *= 2 
	PUSH						; 3
	RA							; 4
	CALL keyboard_callback      ; 8+10
	POP							; 2
	LP REG_M					; 2
	EXAM						; 3
	SLNC                        ; 4     ; Shift left without carry
	ANIA 0x7f					; 4
	ANMA						; 3
	EXAM 						; 3		; M fades away like 0x7e, 0x7c, 0x78, 0x70, 0x60, 0x40
	JRZP kb0105					; 7		; If no key pressed, continue
	CALL kbcalcscan				; (8+144-3)
kb0105:
	LP REG_L					; 2
	LDM							; 2
	LP REG_K					; 2
	ADM							; 3
	DECL						; 4
	LIP PORT_A					; 4
	JRNZM kb0104				; 7		; Loop while L > 0 (6 times)
	;; =================================
	                            ; 91*6-3 (for last JR) = 543 Cycles

	ANIM 0						; 4
	OUTA						; 3		; Port A = 0
	RA							; 4
	LIDP KEY_PORT_1				; 8
	STD							; 2		; Key port 1 = 0
	LIDP KEY_PORT_2				; 8
	STD							; 2		; Key port 2 = 0
	EXAB						; 5
	CPIA 0x4e					; 4
	JRNCP kb0107				; 7
.endif

kb0106:
	SC                          ; (2)
kb0107:
	RTN                         ; 4
	;; =================================
	                            ; PC-1350: 37 PC-2500: 51 Cycles
 
	;; -----------------------------------------------
	;; A: Result from INA
    ;; allways A != 0
    ;; Returns scan code in B
    ;; Worst case cycles: 144
    ;; -----------------------------------------------
kbcalcscan:
	RC                          ; 2
	SL                          ; 2     ; 0x01 --> 0x02 ... 0x40 --> 0x80 
	INCB                        ; 4     ; B += 1, overflow on first call
	JRNCP kb0202                ; 4     ; execute next block on first call
	;; =================================
	                            ; 12 Cycles
kb0201:
	RC                          ; 2
	SL                          ; 2       
	JRCP kb0202                 ; 4
	INCK                        ; 4     ; 0x02 ... 0x80 --> k++ 6 times ... k++ 0 times
	JRM kb0201                  ; 7
	;; =================================
	;; Worst case               ; 19*6-3 (for last JR) = 111 Cycles

kb0202:
	LIA KEY_MULTIPLE            ; 4     ; A = KEY_MULTIPLE
	JRNZP kb0203                ; 4		; Carry is set, when code is reached from within loop, not set on first call
	LP REG_K                    ; 2
	LDM                         ; 2     ; A = K
kb0203:
	EXAB                        ; 5     ; B = A (0x00 ... 0x40), A = B
	RTN                         ; 4
	;; =================================
	                            ; 21 Cycles

    ;; -----------------------------------------------
    ;; Cycles: 
	;;   PC-1350: 104 avg, 106 max
	;;   PC-1360:  82 avg,  84 max
	;;   PC-2500: 117 avg, 119 max
    ;; Tests a bit of a single scan line on key
    ;; port (KB).
	;; Input A (bit mask of scan line),
	;;       I number (0..6) of port A line
	;; Return values: Z is set if bit is not set
	;; Used Registers: I,J,A,P,Port A,C,Z,DP
	;; -------------------------; Cycles -------------	
keyboard_testKP::
.if __PC_2500__
	PUSH						; 3
	ANIA 0x0f					; 4
	LIDP KEY_PORT_1				; 8		; (Key port 1)
	STD							; 2		; A --> Key port 1
	POP							; 2
	SWP							; 2
	ANIA 0x0f					; 4
	LIDP KEY_PORT_2				; 8		; (Key port 2)
	STD							; 2		; A --> Key port 2
	LP REG_I					; 2
	EXAM						; 3
	TO_BITMASK					; 42 avg, 44 max
	LP REG_I					; 2
	EXAM						; 3		; I = test pattern
	LIP PORT_A                  ; 4
	INA                         ; 2		; Port A --> A
	LP REG_I					; 2
	ANMA						; 4		; Set Z if bit is not set
	RA							; 2
	STD							; 2		; 0 --> Key port 2
	LIDP KEY_PORT_1				; 8		; (Key port 1)
	STD							; 2		; 0 --> Key port 1
.else
	LIDP KEY_PORT				; 8		; (Key port)
	STD_HIMEM					; 13/2	; A --> Key port
	LP REG_I					; 2
	EXAM						; 3
	TO_BITMASK					; 42 avg, 44 max
	LP REG_I					; 2
	EXAM						; 3		; I = test pattern
	LIP PORT_A                  ; 4
	INA                         ; 2		; Port A --> A
	LP REG_I					; 2
	ANMA						; 4		; Set Z if bit is not set
	RA							; 2
	STD_HIMEM					; 13/2	; 0 --> Key port
.endif
	RTN							; 4

	;; -----------------------------------------------
	;; This is a dummy callback function. The jump
    ;; address may be overwritten using the macro
    ;; in keyboard.h
	;; -----------------------------------------------
keyboard_callback::
	JP kb0301                   ; 6
kb0301:
	RTN                         ; 4

