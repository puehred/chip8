	;;***************************************************************************
	;;*                                                                         *
	;;*   This program is free software; you can redistribute it and/or modify  *
	;;*   it under the terms of the GNU General Public License as published by  *
	;;*   the Free Software Foundation; either version 2 of the License, or     *
	;;*   (at your option) any later version.                                   *
	;;*                                                                         *
	;;***************************************************************************

	;; -----------------------------------------------
	;; A chip-8 interpreter for the Sharp PC-1350/
	;;  PC-1360/PC-2500
	;; file     : chip8.asm
	;; author   : puehringer edgar
	;; date     : 24.04.2020
	;; assembler: as61860
	;; todo in future versions:
	;;   create chip8 commands for 128x32 pixel mode
	;;   create chip8 commands for left/right scrolling
	;; -----------------------------------------------

.area chip8 (REL)

.globl c8_dec_timers_kbd
.globl c8_dec_timers_disp

.include "target.h"
.include "regs.h"
.include "basic.h"
.include "keyboard.h"
.include "sound.h"
.include "display.h"
.include "memcard.h"
.include "c8font.h"
.include "stub.h"

C8REGS   = REG_XBCD			; Chip-8 has 16 general purpose 8-bit registers, usually referred to as Vx,
							; where x is a hexadecimal digit (0 through F)
C8REG_VF = REG_YBCD+7		; The VF register should not be used by any program,
							; as it is used as a flag by some instructions
C8DEL_TIMER = REG_ZBCD		; Delay timer, 8 bit
C8SND_TIMER = REG_ZBCD+1	; Sound timer, 8 bit
C8STACK_PTR = REG_ZBCD+2	; Stack pointer, 8 bit
C8PROG_CTR  = REG_ZBCD+3	; Program counter, 16 bit
C8REG_I     = REG_ZBCD+5	; I register, 12 bit
C8INT_TIMER = REG_ZBCD+7	; Internal timer, counts 8 times faster than delay and sound timer

C8START_OFFS = 0x0200		; The offset to the start of the chip-8 program (from virtual address 0x0000)

    ;; -----------------------------------------------
	;; On PC-1350 and PC-2500 the start address is
	;; valid for both 8k and 16k RAM cards due to
	;; memory image.
	;; On PC-1360 only one memory card should be used.
	;; The start address is valid for 8k, 16k and 32k
	;; RAM cards due to memory images, although this
	;; is not documented in the service manual.
	;; -----------------------------------------------	
.if __PC_1360__
.org 0x8000+BAS_START_OFFS
.else
.org 0x2000+BAS_START_OFFS
.endif
c8stack:
	.dw 0x0000							; Note that the first two bytes may be changed
	.dw 0x0000							; during NEW/all reset.
	.dw 0x0000							; Ensure high byte of all stack location doesn't
	.dw 0x0000							; change when porting to other models/RAM
	.dw 0x0000							; configurations
	.dw 0x0000
	.dw 0x0000
	.dw 0x0000
	.dw 0x0000
	.dw 0x0000
	.dw 0x0000
	.dw 0x0000
c8stack_end:

.if __PC_2500__

	;; -----------------------------------------------
	;; Chip-8 keyboard mapping:
	;; Original     PC-2500       Scan code
    ;; +-+-+-+-+    +-+-+-+-+     +--+--+--+--+
    ;; |1|2|3|C|    |7|8|9|I| K07 |2e|2f|36|30| K08/7
    ;; +-+-+-+-+    +-+-+-+-+     +--+--+--+--+
    ;; |4|5|6|D|    |4|5|6|/| K06 |27|28|05|35| K01/8
    ;; +-+-+-+-+    +-+-+-+-+     +--+--+--+--+
    ;; |7|8|9|E|    |1|2|3|*| K05 |20|21|0c|0b| K02
    ;; +-+-+-+-+    +-+-+-+-+     +--+--+--+--+
    ;; |A|0|B|F|    |0|.|-|+| K04 |19|1a|13|12| K03
    ;; +-+-+-+-+    +-+-+-+-+     +--+--+--+--+
	;;
	;; ON/BRK: 4d (KON) N: 26 (K06) S: 09 (K02)
	;; -----------------------------------------------

c8keymap:								;   Mapping chip-8 key to scancode
	.db KEY_NUM_PERIOD					; 0 Ensure high byte of all keymap location doesn't
	.db KEY_NUM_7						; 1 change when porting to other models/RAM configurations
	.db KEY_NUM_8						; 2
	.db KEY_NUM_9						; 3
	.db KEY_NUM_4						; 4
	.db KEY_NUM_5						; 5
	.db KEY_NUM_6						; 6
	.db KEY_NUM_1						; 7
	.db KEY_NUM_2						; 8
	.db KEY_NUM_3						; 9
	.db KEY_NUM_0						; A
	.db KEY_NUM_MINUS					; B
	.db KEY_INS							; C
	.db KEY_NUM_SLASH					; D
	.db KEY_ASTERISK					; E
	.db KEY_PLUS						; F

.else

	;; -----------------------------------------------
	;; Chip-8 keyboard mapping:
	;; Original     PC-1350/60   Scan code
    ;; +-+-+-+-+    +-+-+-+-+    +--+--+--+--+
    ;; |1|2|3|C|    |7|8|9|(|    |37|30|29|22|
    ;; +-+-+-+-+    +-+-+-+-+    +--+--+--+--+
    ;; |4|5|6|D|    |4|5|6|/|    |36|2f|28|21|
    ;; +-+-+-+-+    +-+-+-+-+    +--+--+--+--+
    ;; |7|8|9|E|    |1|2|3|*|    |35|2e|27|20|
    ;; +-+-+-+-+    +-+-+-+-+    +--+--+--+--+
    ;; |A|0|B|F|    |0|.|+|-|    |34|2d|26|1f|
    ;; +-+-+-+-+    +-+-+-+-+    +--+--+--+--+
	;;                Scan line: K5 K4 K3 K2
	;;
	;; ON/BRK: 3f (KON) N: 02 (IA1) S: 24 (K03)
	;; -----------------------------------------------

c8keymap:								;   Mapping chip-8 key to scancode
	.db KEY_PERIOD						; 0 Ensure high byte of all keymap location doesn't
	.db KEY_7							; 1 change when porting to other models/RAM configurations
	.db KEY_8							; 2
	.db KEY_9							; 3
	.db KEY_4							; 4
	.db KEY_5							; 5
	.db KEY_6							; 6
	.db KEY_1							; 7
	.db KEY_2							; 8
	.db KEY_3							; 9
	.db KEY_0							; A
	.db KEY_PLUS						; B
	.db KEY_PARENLEFT					; C
	.db KEY_SLASH						; D
	.db KEY_ASTERISK					; E
	.db KEY_MINUS						; F

.endif

c8orig_x:								; Store the original X register here
	.dw 0

	;; -----------------------------------------------
	;; Writes a c8-style character and inreases
	;; the graphics X cursor by 5
	;; -----------------------------------------------
c8putchar:
	LIDP display_gcur_x
	LDD
	PUSH
	LIA 5
	CALL display_c8draw
	LIDP display_gcur_x
	POP
	ADIA 5
	STD
	RTN

.if __PC_1350__ + __PC_2500__
;main									; ensure main starts at 0x206c = 8300
	JRP main_cont
;ensure_c8_loaded
	JRP ensure_c8_loaded
;c8_prog_start							; c8 prog start address - PEEK it from here
	.db <c8_prog, >c8_prog
.endif

	;; -----------------------------------------------
	;; Common xor function for the XOR operator and
	;; the random number generator
	;; Used registers and flags: A,B,J,P,C,Z
	;; 23 bytes, 60 cycles
	;; -----------------------------------------------
c8_xor:
	XOMA REG_B
	RTN

c8orig_sp:								; Store the original stack pointer here
	.db 0

.if __PC_1360__
;main									; ensure main starts at 0x8084 = 32900
	JRP main_cont
;ensure_c8_loaded
	JRP ensure_c8_loaded
;c8_prog_start							; c8 prog start address - PEEK it from here
	.db <c8_prog, >c8_prog
.endif

	;; -----------------------------------------------
	;; Writes 'Y' to BASIC std var T$. T$ must be
	;; initialized with e.g. 'N' in BASIC loader
	;; -----------------------------------------------
ensure_c8_loaded:
	LIDP BASIC_STDVAR_T+1
	LIA 'Y
	STD_HIMEM
	RTN

	;; -----------------------------------------------
	;; Writes a c8-style character and inreases
	;; the graphics X cursor by 5
	;; -----------------------------------------------
c8putchar_BA:
	LP REG_XL
	LIQ REG_A
	MVB
	JRM c8putchar

main_cont:
	CALL display_init
	DISP_ON
	; Save original stack pointer
	LDR
	LIDP c8orig_sp
	STD
	; Save the X register
	LIDP c8orig_x
	LP   REG_XL
	EXBD
	; Set sound pitch to 2 kHz
	LIDP c8snd_stat
	ANID 0xef
	; Clear screen
	CALL cls_full
	; Draw screen bound
	CALL c8bounds

	LIA 149
	SET_MAX_GCUR_X

	CALL c8_write_sound

	; Write sound status (on/off) to display.
	; Sets also the screen bounds for bitblit code to 63
	CALL print_snd_stat

	; Init timers and stack pointer
	RA
	LP REG_ZBCD
	LII 8-1
	FILM

	; Set display and keyboard callback function
    SET_DISP_CALLBACK c8_dec_timers_disp
	SET_KBD_CALLBACK c8_dec_timers_kbd

	; Init random number generator. The random number
	; sequence can be changed with the BASIC command RANDOM
	; on PC-1350/PC-1360. For PC-2500 I don't know the
	; memory location
.if __PC_1350__ + __PC_1360__
	LIDP BAS_RANDOM+3
	LDD
	CPIA 0
	JRNZP c8_seed_gt_null
.endif
	LIA 70
c8_seed_gt_null:
	LIDP c8rnd_data
	STD

	; Set program counter
	LIA >C8START_OFFS
	LP C8PROG_CTR+1
	EXAM

c8forever:
	; Test break key and timer
	TEST TEST_BRK+TEST_CNT_2       		; Test KON, which is wired to the break key
										;  and 2ms counter
	JPNZ c8break                		; If set one of then is set, jump ahead

c8forever_cont:

	; Increase program counter
	LP C8PROG_CTR
	RA
	EXAB
	LIA 2
	ADB
	; Read chip-8 instruction
	LP REG_XH							; start of chip-8 address range to X
	LIA >(c8_prog-C8START_OFFS)	 
	EXAM
	LP REG_XL
	LIA <(c8_prog-C8START_OFFS)	 
	EXAM
	LIQ C8PROG_CTR						; program counter to BA
	LP REG_A
	MVB
	; LP REG_XL not needed because MVB with J=1 increases REG_A TO REG_XL
	ADB									; X is real position in memory now

	DXL
	EXAB
	DXL
	LP REG_I
	EXAM
	LDM
	ANIA 0xf0
	SWP									; I = opcode_h, B = opcode_l, A = opcode 1. nibble 

	PTC 16, c8forever
	DTC
	.CASE 0x00, c8opcode0
	.CASE 0x01, c8opcode1
	.CASE 0x02, c8opcode2
	.CASE 0x03, c8opcode3
	.CASE 0x04, c8opcode4
	.CASE 0x05, c8opcode5
	.CASE 0x06, c8opcode6
	.CASE 0x07, c8opcode7
	.CASE 0x08, c8opcode8
	.CASE 0x09, c8opcode9
	.CASE 0x0a, c8opcodeA
	.CASE 0x0b, c8opcodeB
	.CASE 0x0c, c8opcodeC
	.CASE 0x0d, c8opcodeD
	.CASE 0x0e, c8opcodeE
	.CASE 0x0f, c8opcodeF
	.DEFAULT    c8op_unknown

; ============================================================================
c8opcode0:								; Clear screen, return from subroutine, exit
	LDM
	ANIA 0xff							; Check if opcode_h is 0x00
	JRNZP c8op02
	EXAB
	CPIA 0xee							; opcode_l == 0xee?
	JRNZP c8op01
	LP REG_XH							; Stack pointer+1 to X
	LIA >c8stack	 
	EXAM
	LP C8STACK_PTR
	LDM
	ADIA (<c8stack)+1
	LP REG_XL
	EXAM
	DX									; (DP) points to stack now
	LP C8PROG_CTR
	MVBD								; (DP) --> program counter
	LP C8STACK_PTR
	SBIM 2								; Stack pointer -= 2
	JRNCP c8op00
	LIA c8stack_end-c8stack-2           ; On Stack underflow set it to end of stack
	EXAM
c8op00:
	RTN
c8op01:
	CPIA 0xe0							; opcode_l == 0xe0?
	JPZ cls_c8							; Clear screen
	CPIA 0xfd							; opcode_l == 0xfd?
    JPZ c8exit
c8op02:
	JP c8op_unknown

; ============================================================================
c8opcode2:								; Call instruction
	LP C8STACK_PTR
	ADIM 2								; Stack pointer += 2
	CPIM 24
	JRNZP c8op20
	ANIM 0								; On Stack overflow set it to 0
c8op20:
	LP REG_YH							; Stack pointer+1 to Y
	LIA >c8stack	 
	EXAM
	LP C8STACK_PTR
	LDM
	ADIA (<c8stack)+1
	LP REG_YL
	EXAM
	LP C8PROG_CTR						; Write program counter to stack
	LDM
	DYS	
	LP C8PROG_CTR+1
	LDM
	IYS	
	; the rest is the same as jump, so we set LP to REG_I and have no RTN here
	LP REG_I
; ============================================================================
c8opcode1:								; Jump instruction
	EXAM								; chip-8 address to BA
	ANIA 0x0f
	EXAB
	LIQ REG_A							; BA to program counter
	LP C8PROG_CTR
	MVB		
	RTN

; ============================================================================
c8opcode3:								; SE Vx, byte
	EXAM								; Register# to A
	ANIA 0x0f
	ADIA C8REGS							; Add offset to chip-8 registers location
	STP
	EXAB								; B -> A
	CPMA
	JRZP c8op_skip
	RTN

; ============================================================================
c8opcode4:								; SNE Vx, byte
	EXAM								; Register# to A
	ANIA 0x0f
	ADIA C8REGS							; Add offset to chip-8 registers location
	STP
	EXAB								; B -> A
	CPMA
	JRNZP c8op_skip
	RTN

; ============================================================================
c8opcode5:								; SE Vx, Vy - Skip next instruction if Vx = Vy
	ANIM 0x0f							; Register# of Vx to I
	ADIM C8REGS							; I is now internal RAM location of Vx
	LDM
	STP									; P is now internal RAM location of Vx
	LDM									; A is now content of Vx
	PUSH								; Push content of Vx to stack
	EXAB
	ANIA 0xf0
	SWP									; Register# of Vy to A
	ADIA C8REGS							; A is now internal RAM location of Vy
	STP									; P is now internal RAM location of Vy
	POP									; Fetch content of Vx from stack
	CPMA
	JRZP c8op_skip
	RTN

; ============================================================================
c8opcode6:								; Load immediate
	EXAM								; Register# to A
	ANIA 0x0f
	ADIA C8REGS							; Add offset to chip-8 registers location
	STP
	EXAB								; B -> Vx (pointed to by P)
	EXAM
	RTN

; ============================================================================
c8opcode7:								; ADD Vx, byte
	EXAM								; Register# to A
	ANIA 0x0f
	ADIA C8REGS							; Add offset to chip-8 registers location
	STP
	EXAB								; B -> A
	ADM									; Vx (pointed to by P) = Vx + A
	RTN

; ============================================================================
c8opcode8:								; Arithmetic, logical and shift instr.
	ANIM 0x0f							; Register# of Vx to I
	ADIM C8REGS							; I is now internal RAM location of Vx
	LP REG_B
	LDM
	ANIA 0x0f
	PUSH								; Push lowest nibble of opcode to stack
	LDM
	ANIA 0xf0
	SWP									; Register# of Vy to A
	ADIA C8REGS							; A is now internal RAM location of Vy
	STP
	LDM
	EXAB								; B = content of Vy
	LP REG_I
	LDM
	STP									; P points to Vx
	POP									; Fetch lowest nibble of opcode from stack
	CPIA 4								; if A >= 4 jump ahead
	JRNCP c8op80
	PTC 4, c8op81
	DTC
	.CASE 0x00, c8opcode8_00
	.CASE 0x01, c8opcode8_01
	.CASE 0x02, c8opcode8_02
	.CASE 0x03, c8opcode8_03
	.DEFAULT    c8op_unknown
c8op81:
	RTN

c8op80:
	PTC 5, c8op82
	DTC
	.CASE 0x04, c8opcode8_04
	.CASE 0x05, c8opcode8_05
	.CASE 0x06, c8opcode8_06
	.CASE 0x07, c8opcode8_07
	.CASE 0x0e, c8opcode8_0e
	.DEFAULT    c8op_unknown
c8op82:
	RA									; Shift carry to A and store it to Vf
	SL
	LP C8REG_VF
	EXAM
	RTN

c8opcode8_00:							; LD Vx, Vy
	EXAB
	EXAM
	RTN

c8opcode8_01:							; OR Vx, Vy
	EXAB
	ORMA
	RTN

c8opcode8_02:							; AND Vx, Vy
	EXAB
	ANMA
	RTN

c8opcode8_03:							; XOR Vx, Vy
	EXAM
;	XOMA REG_B
	CALL c8_xor
	LP REG_I
	LDM
	STP									; P points to Vx
	EXAB								; Result of XOR --> A
	EXAM								; Result to Vx
	RTN

c8opcode8_04:							; ADD Vx, Vy
	EXAB
	ADM
	RTN
c8opcode8_05:							; SUB Vx, Vy
	EXAB
	SBM
	JRCP c8op83							; invert carry
	SC
	RTN
c8opcode8_07:							; SUBN Vx, Vy
	EXAB
	EXAM
	SBM
	JRCP c8op83							; invert carry
	SC
	RTN
c8op83:
	RC
	RTN
c8opcode8_06:							; SHR Vx {, Vy}
	EXAB								; See https://en.wikipedia.org/wiki/CHIP-8 Note b.
	RC
	SR
	EXAM
	RTN
c8opcode8_0e:							; SHL Vx {, Vy}
	EXAB								; See https://en.wikipedia.org/wiki/CHIP-8 Note b.
	RC
	SL
	EXAM
	RTN

; ============================================================================
c8opcode9:								; SNE Vx, Vy - Skip next instruction if Vx != Vy
	ANIM 0x0f							; Register# of Vx to I
	ADIM C8REGS							; I is now internal RAM location of Vx
	LDM
	STP									; P is now internal RAM location of Vx
	LDM									; A is now content of Vx
	PUSH								; Push content of Vx to stack
	EXAB
	ANIA 0xf0
	SWP									; Register# of Vy to A
	ADIA C8REGS							; A is now internal RAM location of Vy
	STP									; P is now internal RAM location of Vy
	POP									; Fetch content of Vx from stack
	CPMA
	JRZP c8op90
c8op_skip:
	LP C8PROG_CTR						; increase program counter
	RA
	EXAB
	LIA 2
	ADB
c8op90:
	RTN

; ============================================================================
c8opcodeA:								; Set I to nnn
	EXAM								; chip-8 address to BA
	ANIA 0x0f
	EXAB
	LIQ REG_A							; BA to chip-8 register I
	LP C8REG_I
	MVB		
	RTN

; ============================================================================
c8opcodeB:								; JP V0, addr - Jump to location nnn + V0
										; Leaves I unchanged
	EXAM								; chip-8 address to BA
	ANIA 0x0f
	EXAB
	LIQ REG_A							; BA to program counter
	LP C8PROG_CTR
	MVB
	RA
	EXAB								; B = 0
	LP C8REGS
	LDM									; A = V0
	LP C8PROG_CTR
	ADB									; Add BA (= V0) to program counter
	LP C8PROG_CTR+1						; overflow detection
	TSIM 0xf0
	JPNZ c8op_access_violation
	RTN

; ============================================================================
c8opcodeC:								; RND Vx, byte
	ANIM 0x0f							; Register# of Vx to I
	ADIM C8REGS							; I is now internal RAM location of Vx
	EXAB
	PUSH								; Push mask byte to stack
	CALL c8_rnd
	PUSH								; Push random number (0..255) to stack
	LP REG_I
	LDM
	STP									; P points to Vx
	POP									; Fetch random number (0..255) to stack
	EXAM								; Vx = random number (0..255)
	POP									; Fetch mask byte from stack
	ANMA								; Vx = Vx & kk
	RTN

; ============================================================================
c8opcodeD:								; DRW Vx, Vy, nibble
	EXAM								; Register# of Vx to A
	ANIA 0x0f
	ADIA C8REGS							; A is now internal RAM location of Vx
	STP
	LDM									; Load Vx
	ANIA =0x3f							; A = A % 64
	LIDP display_gcur_x					; Store it to graphics cursor X
	STD
	EXAB								; Register# of Vy to A
	PUSH								; Push opcode_l to stack
	ANIA 0xf0
	SWP
	ADIA C8REGS							; A is now internal RAM location of Vy
	STP
	LDM									; Load Vy
	ANIA =0x1f							; A = A % 32
	LIDP display_gcur_y					; Store it to graphics cursor Y
	STD
	LP REG_XH							; start of chip-8 address range-1 to X
	LIA >(c8_prog-C8START_OFFS-1)
	EXAM
	LP REG_XL
	LIA <(c8_prog-C8START_OFFS-1)
	EXAM
	LIQ C8REG_I							; chip-8 register I to BA
	LP REG_A
	MVB
	; LP REG_XL not needed because MVB with J=1 increases REG_A TO REG_XL
	ADB									; X is real position in memory-1 now
	POP									; Fetch opcode_l from stack
	ANIA 0x0f							; Set number of bytes to draw
	JPZ c8op_unknown
	CALL display_c8draw
	PUSH								; Push mumber of non zero bytes handled
	RA
	JRZP c8opd0							; Zero flag means no collisions
	LIA 1
c8opd0:
	LP C8REG_VF							; Vf = 1 if collisions, 0 otherwise
	EXAM
	POP									; Fetch number of non zero bytes handled from stack
	SRNC								; non zero bytes to missed timer ticks calculation
	SR
	ADIA 3								; A=3+A/4
    JP c8_dec_timers_disp				; Respect missed timer tics
;	RTN

; ============================================================================
c8opcodeE:								; Keyboard functions SKP and SKNP
	ANIM 0x0f							; Register# of Vx to I
	ADIM C8REGS							; I is now internal RAM location of Vx
	EXAB								; A = opcode_l
	CPIA 0xa1							; opcode_l == 0xa1?
	JRZP c8ope0
	CPIA 0x9e							; opcode_l == 0x9e?
	JRZP c8ope0
	JP c8op_unknown
c8ope0:
	PUSH								; Push opcode_l to stack
	LP REG_XH							; high byte of c8keymap to XH
	LIA >c8keymap	 
	EXAM
	LP REG_I
	LDM
	STP									; P points to Vx
	LDM 								; A = Vx (chip-8 key)
	ADIA (<c8keymap)+1					; Add low byte of c8keymap+1
	LP REG_XL							; and write to XL
	EXAM
	DXL									; (DP) points to c8keymap+key now, A=scan code
	LP REG_I							; I=A
	EXAM
	SBIM KEYPORT_OFFS-7					; 7 will be subtracted in first loop
	RA
.if __PC_1360__
c8ope1:
	INCA
.else
	SC
c8ope1:
	SL
.endif
	SBIM 7
	CPIM 7
	JRNCM c8ope1
	; A is bit mask for key port now, I=0..6
	; scan codes are invers to IA port pins, we have to flip it
	PUSH								; Push bit mask for key port to stack
	LIA 6
	EXAM
	SBM
	POP									; Fetch bit mask for key port from stack
    CALL keyboard_testKP
	POP									; Fetch opcode_l to stack
	JRZP c8ope2							; Z=1 is key is not pressed -> jump ahead
	; key is pressed
	SR									; opcode_l == a1 -> C = 1, opcode_l == 9e --> C = 0
	JPNC c8op_skip						; if C == 0 (opcode_l == 9e) skip instruction
	RTN
c8ope2:
	; key is not pressed
	SR									; opcode_l == a1 -> C = 1, opcode_l == 9e --> C = 0
	JPC c8op_skip						; if C == 1 (opcode_l == a1) skip instruction
	RTN

; ============================================================================
c8opcodeF:								; Various instructions, handled in
										; another table jump
	ANIM 0x0f							; Register# to I
	EXAB								; I = Register# of Vx, A = opcode_l 
;	PTC 9, c8opf0
	PTC 12, c8opf0
	DTC
	.CASE 0x00, c8opcodef_17			; PITCH=VX, better use FX17, fish'n chips doesn't crash on it
	.CASE 0x07, c8opcodef_07
	.CASE 0x0a, c8opcodef_0a
	.CASE 0x15, c8opcodef_15
	.CASE 0x17, c8opcodef_17			; PITCH=VX, Set the Pitch of the Tone Generator to VX
	.CASE 0x18, c8opcodef_18
	.CASE 0x1e, c8opcodef_1e
	.CASE 0x29, c8opcodef_29
	.CASE 0x33, c8opcodef_33
	.CASE 0x55, c8opcodef_55
	.CASE 0x65, c8opcodef_65
	.CASE 0x75, c8opcodef_75
	.DEFAULT    c8op_unknown
c8opf0:
	RTN

; ============================================================================
c8opcodef_07:							; LD Vx, DT - Set Vx = delay timer
	LP C8DEL_TIMER						; Push delay timer to stack
	LDM
	PUSH
	LP REG_I
	EXAM								; Register# of Vx to A
	ANIA 0x0f
	ADIA C8REGS							; A is now internal RAM location of Vx
	STP
	POP									; Fetch delay timer from stack
	EXAM
	RTN

; ============================================================================
c8opcodef_0a:							; LD Vx, K - Wait key & store value in Vx
	ADIM C8REGS							; A is now internal RAM location of Vx
	EXAM
	PUSH
opkbd3:
	CALL c8_kbread_and_idle
	JRNCM opkbd3
	LP REG_I							; I = scancode
	EXAM
	LIA KEY_BREAK						; if I == BREAK_KEY
	CPMA
	JRNZP opkbd4
	POP									; Fetch internal RAM location of Vx from stack
	LP C8PROG_CTR						; Decrease program counter
	RA
	EXAB
	LIA 2
	SBB
	RTN									; ... and handle break key the standard way
opkbd4:
	LIA KEY_S							; if I == KEY_S
	CPMA
	JRNZP opkbd6
	CALL toggle_snd_stat
opkbd5:
	CALL keyboard_raw_inkey
	JRCM opkbd5							; Loop until key release
	JP opkbd3
opkbd6:
	LP REG_XH
	LIA >(c8keymap+0x10)
	EXAM
	LP REG_XL
	LIA <(c8keymap+0x10)
	EXAM
	LIB 0x0f
	LP REG_I
opkbd:
	DXL									; X--; A = [X]
	CPMA
	JRZP opkbd2
	DECB
	JRNCM opkbd
	JP opkbd3
opkbd2:
	POP
	STP									; P = [Vx]
	EXAB								; A = B (index of scan code)
	EXAM								; Vx = index of scan code
	RTN

; ============================================================================
c8opcodef_15:							; LD DT, Vx - Set delay timer = Vx
	EXAM								; Register# of Vx to A
	ANIA 0x0f
	ADIA C8REGS							; A is now internal RAM location of Vx
	STP
	LDM									; Load Vx
	LP C8DEL_TIMER						; Delay timer = Vx
	EXAM
	RTN

; ============================================================================
c8opcodef_17:							; PITCH=VX, Set the Pitch of the Tone Generator to VX
										; 0 .. 0x0f = 2 kHz, everything else 4 kHz
	EXAM								; Register# of Vx to A
	ANIA 0x0f
	ADIA C8REGS							; A is now internal RAM location of Vx
	STP
	LDM
	TSIA 0xf0
	LIDP c8snd_stat
	LDD
	JRZP pitch_low
	ORIA 0x10
pitch_cont:
	STD
	LP C8SND_TIMER
	TSIM 0xfe							; If sound timer < 2, don't apply pitch
	JRZP pitch_skip
	SND_REG_A
pitch_skip:	
	RTN

pitch_low:
	ANIA 0xef
	JRM pitch_cont

; ============================================================================
c8opcodef_18:							; LD ST, Vx - Set sound timer = Vx
	EXAM								; Register# of Vx to A
	ANIA 0x0f
	ADIA C8REGS							; A is now internal RAM location of Vx
	STP
	LDM									; Load Vx
	LP C8SND_TIMER						; Sound timer = Vx
	EXAM
	LDM
	TSIA 0xfe							; If sound timer < 2, don't turn on sound
	JRZP c8opf1
	LIDP c8snd_stat						; If sound status == 0 or 0x10, don't turn on sound
	LDD
	TSIA 0x20
	JRZP c8opf1
	SND_REG_A
c8opf1:
	RTN

; ============================================================================
c8opcodef_1e:							; ADD I, Vx
	LP C8REG_I+1						; I = I & 0x0fff
	ANIM 0x0f
	RA									; B = 0
	EXAB
	LP REG_I
	EXAM								; Register# to A
	ADIA C8REGS							; Add offset to chip-8 registers location
	STP
	LDM									; A = Vx
	LP C8REG_I
	ADB									; I = I + Vx
	LP C8REG_I+1
	LDM
	ANIA 0xf0							; overflow detection - See
	SWP									;  https://en.wikipedia.org/wiki/CHIP-8 Note c.
	LP C8REG_VF
	EXAM
	RTN

; ============================================================================
c8opcodef_29:							; LD F, Vx - Set I = location of sprite for digit Vx
	EXAM								; Register# of Vx to A
	ANIA 0x0f
	ADIA C8REGS							; A is now internal RAM location of Vx
	STP
	LDM									; Load Vx
	ANIA 0x0f							; Only characters 0..f are valid
	CALL c8digitaddr
	LIB >(c8_prog-C8START_OFFS-1)		; Address of digit - chip8 set
	LIA <(c8_prog-C8START_OFFS-1)
	LP REG_XL
	SBB
	LIQ REG_XL							; X to chip-8 register I
	LP C8REG_I
	MVB		
	RTN

; ============================================================================
; We do a https://en.wikipedia.org/wiki/Double_dabble here and use REG_WBCD
; as scratch area
c8opcodef_33:							; LD B, Vx - Store BCD rep. of Vx in memory loc. I..I+2
	EXAM								; Register# of Vx to A
	ANIA 0x0f
	ADIA C8REGS							; A is now internal RAM location of Vx
	STP
	LDM									; Load Vx
	LP REG_WBCD+3
	EXAM								; Store it to end of scratch area
	LP REG_WBCD							; Erase rest of scratch area
	ANIM 0x00
	LP REG_WBCD+1
	ANIM 0x00
	LIA 7								; Loop 8 times
	PUSH
opbcd1:
	LP REG_WBCD+1						; Load ones and tens
	LDM
	CPIA 0x50							; High nibble < 5? Jump ahead
	JRCP opbcd2
	ADIA 0x30							; Add 3 to high nibble if >= 5
	EXAM								; Save high nibble
opbcd2:
	ANIA 0x0f							; Mask low nibble
	CPIA 5								; Low nibble < 5? Jump ahead
	JRCP opbcd3
	ADIA 3								; Add 3 to low nibble if >= 5
	ORMA								; Save low nibble
	ORIA 0xf0
	ANMA
opbcd3:
	LP REG_WBCD+3						; Shift binary value
	LDM
	SL
	EXAM
	LP REG_WBCD+1						; Shift ones and tens. Carry comes from binary value
	LDM
	SL
	EXAM
	LP REG_WBCD							; Shift hundreds. Carry comes from binary value
	LDM
	SL
	EXAM
	LOOP opbcd1
	LP REG_WBCD+1						; Split ones and tens to two bytes
	LDM
	LP REG_WBCD+2
	EXAM
	LDM
	ANIM 0x0f
	SWP
	ANIA 0x0f
	LP REG_WBCD+1
	EXAM
	LIA REG_WBCD-1						; Write source address-1 for copy loop to REG_K
	LP REG_K
	EXAM
	LII 2								; Copy 3 bytes
	JRP c8opf_intram_to_i				; Reuse code of opcode Fx55

; ============================================================================
c8opcodef_55:							; LD [I], Vx
	LIA C8REGS-1						; Write source address-1 for copy loop to REG_K
	LP REG_K
	EXAM
c8opf_intram_to_i:
										; REG_I is the register# and also the
										; counter for the block move instr.
	LP C8REG_I+1						; Chip-8 register I underflow detection
	LDM
	CPIA >C8START_OFFS
	JRCP c8op_access_violation
	LP REG_I							; Chip-8 register I overflow detection
	RA
	EXAB
	LDM									; BA = I
	PUSH								; Push I for increase of chip-8 register I
	PUSH								; Push I for LOOP
	LP C8REG_I
	ADB									; Chip-8 register I = I + Vx
	LP C8REG_I+1
	TSIM 0xf0
	JRNZP c8op_access_violation
	LP C8REG_I
	SBB									; Undo addition of Vx
	LP REG_XH							; start of chip-8 address range-1 to X
	LIA >(c8_prog-C8START_OFFS-1)	 
	EXAM
	LP REG_XL
	LIA <(c8_prog-C8START_OFFS-1)
	EXAM
	LIQ C8REG_I							; chip-8 register I to BA
	LP REG_A
	MVB
	; LP REG_XL not needed because MVB with J=1 increases REG_A TO REG_XL
	ADB									; X is real position in memory-1 now
	LP REG_K							; P = K (copy source address-1)
	LDM
	STP
c8opf2:									; Chip8 registers --> (DP..DP+I)
	IX
	INCP
	MVDM
	LOOP c8opf2
	LP REG_K							; P = K (copy source address-1)
;	CPIM C8REGS-1						; If K < start of c8 regs, don't incr. I
;	JRNCP c8opf_incI
	CPIM C8REG_VF						; If K > end of c8 regs, don't incr. I
	JRCP c8opf_incI
	POP									; Fetch register# from stack
	RTN

; ============================================================================
c8opcodef_65:							; LD Vx, [I]
										; REG_I is the register# and also the
										; counter for the block move instr. 
	LP REG_XH							; start of chip-8 address range+1 to X
	LIA >(c8_prog-C8START_OFFS+1)	 
	EXAM
	LP REG_XL
	LIA <(c8_prog-C8START_OFFS+1)
	EXAM
	LIQ C8REG_I							; chip-8 register I to BA
	LP REG_A
	MVB
	; LP REG_XL not needed because MVB with J=1 increases REG_A TO REG_XL
	ADB									; X is real position in memory+1 now
	LP REG_I
	LDM
	PUSH								; Push I (register#) on stack
	DX									; DP is real position in memory now
	LP C8REGS
	MVWD								; (DP..DP+I) --> chip8 registers
c8opf_incI:								; See https://en.wikipedia.org/wiki/CHIP-8 Note d.
	POP									; Fetch register# from stack,
	INCA								;  increase it by 1 and
	LIB 0
	LP C8REG_I
	ADB									;  add it to chip-8 register I
	RTN

; ============================================================================
c8opcodef_75:							; DISP VX, Display the value of VX on the COSMAC Elf hex display
										; Use only for debugging, most c8 interpreters can't handle it
	EXAM								; Register# of Vx to A
	ANIA 0x0f
	ADIA C8REGS							; A is now internal RAM location of Vx
	STP
	LDM
	PUSH
	; widen screen bounds
	LIA 149
	SET_MAX_GCUR_X
	LIDP VRAM_L3C4						; Clear 4. display block of 3. row
	CALL display_clr_vram
	LIA 16
	LIDP display_gcur_y
	STD
	LIA 90
	LIDP display_gcur_x
	STD
	POP
	PUSH
	SWP
	ANIA 0x0f
	CALL c8digitaddr
	CALL c8putchar
	POP
	ANIA 0x0f
	CALL c8digitaddr
	CALL c8putchar
	; narrow screen bounds
	LIA 63
	SET_MAX_GCUR_X
	RTN


	;; -----------------------------------------------
	;; Unknown instruction handling
	;; -----------------------------------------------
c8op_unknown:
	CALL c8exit_nostack
	LIA 0xf								; Will display an "ERROR ?"
	JRP c8op_error

	;; -----------------------------------------------
	;; Access violation handling
	;; -----------------------------------------------
c8op_access_violation:
	CALL c8exit_nostack
	RA									; Will display an "ERROR 0"
c8op_error:
	LP 0x34
	EXAM
	LIP PORT_F
	ANIM 0xfe
	OUTF
	LIDP c8orig_sp						; Restore original stack pointer
	LDD
	STR
	POP									; Remove 2 bytes from stack
	POP
	SC
	RTN

	;; -----------------------------------------------
	;; Break mode handling
	;; -----------------------------------------------
c8break:
	CALL c8_dec_timers_notest
	TEST TEST_BRK                   	; Test KON, which is wired to the break key
	JPZ c8forever_cont
c8break_notimer:
	TEST TEST_BRK                   	; Test KON, which is wired to the break key
	JRNZM c8break_notimer
	SND_OFF
	; enable writing on the right half of the screen
	LIA 149
	SET_MAX_GCUR_X
	CALL c8_write_pause

c8_break_keyloop1:
;	CALL keyboard_raw_inkey
	CALL c8_kbread_and_idle
    JRNCM c8_break_keyloop1
    PUSH								; Push keycode to stack
c8_break_keyloop2:
	CALL keyboard_raw_inkey
    JRCM c8_break_keyloop2				; Loop until key release
    POP
	CPIA KEY_BREAK						; Exit on KEY_BREAK
	JRZP c8exit
	CPIA KEY_N							; Reset and exit on KEY_N
	JRZP c8reset_and_exit
	CPIA KEY_S							; Toggle sound on KEY_S
	JRNZP c8_break_skipsnd
	CALL toggle_snd_stat
	JRM c8_break_keyloop1	
c8_break_skipsnd:						; Continue to normal c8 executon on any other key
	LIA 149
	SET_MAX_GCUR_X
	CALL c8_write_pause					; Write "PAUSE" to erase it (bitblit xor mode)
	LIA 63
	SET_MAX_GCUR_X
	JP c8forever_cont

; ============================================================================
C8MINPROG_LENGTH = c8minprog_end-c8minimal_prog

c8reset_and_exit:
	LIDP c8minimal_prog					; Overwrite c8-program with minimal
	LP REG_WBCD							; program
	LII C8MINPROG_LENGTH-1
	MVWD
	LIDP c8_prog
	LP REG_WBCD
	EXWD
	CALL chk_memcard					; Calc RAM start offset
.if __PC_1360__
	ANIA 0x7f							; Filter 0x80 (32k) because it's the default
										; 8k or less doesn't need to be handled, because
										; program couldn't be loaded with this config
.else
	ANIA 0x3f							; Filter 0x40 (16k) because it's the default
										; No RAM card doesn't need to be handled, because
										; program couldn't be loaded with this config
.endif
	ADIA >(c8_prog+C8MINPROG_LENGTH-2)
	EXAB
	LIA <(c8_prog+C8MINPROG_LENGTH-2)
	LIDP BAS_START_PTR					; Set pointer to start of BASIC text
	LP REG_A							; Respects 8k & 16k RAM cards
	EXBD
	CALL c8_write_pause
	CALL c8_write_new
c8exit:
	LIDP c8orig_sp						; Restore original stack pointer
	LDD
	STR
c8exit_nostack:
	CALL cls_c8							; Clear c8 part of the screen
	SND_OFF								; Sound off
	LIDP c8orig_x						; Restore original X register
	LP   REG_XL
	MVBD
	RTN									; and return to basic (if call to c8exit)

	;; -----------------------------------------------
	;; Keyboard read; after delay and sound timer are
	;; have turned to zero if halts 512 ms in a loop
	;; until a key is pressed (power saving)
	;; -----------------------------------------------
c8_kbread_and_idle:
	CALL keyboard_raw_inkey
	JRCP kbread_exit
	LP C8DEL_TIMER
	TSIM 0xff
	JRNZM c8_kbread_and_idle	; Don't idle if delay timer != 0
	LP C8SND_TIMER
	TSIM 0xff
	JRNZM c8_kbread_and_idle	; Don't idle if sound timer != 0
	KBD_SET_KB
	KBD_IDLE
	JRM c8_kbread_and_idle
kbread_exit:
	RTN

	;; -----------------------------------------------
	;; Writes "SOUND O"
	;; -----------------------------------------------
c8_write_sound:
	LIA 1
	LIDP display_gcur_y
	STD
	LIA 87
	LIDP display_gcur_x
	STD

	LIA 5								; Looks like "S"
	CALL c8digitaddr
	CALL c8putchar

	LIA 0								; Looks like "O"
	CALL c8digitaddr
	CALL c8putchar

	LIB >(c8char_U-1)					; U
	LIA <(c8char_U-1)
	CALL c8putchar_BA

	LIB >(c8char_N-1)					; N
	LIA <(c8char_N-1)
	CALL c8putchar_BA

	LIA 0x0d							; D
	CALL c8digitaddr
	CALL c8putchar
	LIDP display_gcur_x					; 3 pixels space
	LDD
	ADIA 3
	STD
	LIA 0								; Looks like "O"
	CALL c8digitaddr
	CALL c8putchar
	RTN

	;; -----------------------------------------------
	;; Writes "PAUSE"
	;; -----------------------------------------------
c8_write_pause:
	LIA 8
	LIDP display_gcur_y
	STD
	LIA 87
	LIDP display_gcur_x
	STD
	LIB >(c8char_P-1)
	LIA <(c8char_P-1)
	CALL c8putchar_BA
	LIA 0x0a
	CALL c8digitaddr
	CALL c8putchar
	LIB >(c8char_U-1)
	LIA <(c8char_U-1)
	CALL c8putchar_BA
	LIA 5								; Looks like "S"
	CALL c8digitaddr
	CALL c8putchar
	LIA 0x0e
	CALL c8digitaddr
	CALL c8putchar
	RTN

	;; -----------------------------------------------
	;; Writes "NEW"
	;; -----------------------------------------------
c8_write_new:
	LIA 8
	LIDP display_gcur_y
	STD
	LIA 87
	LIDP display_gcur_x
	STD
	LIB >(c8char_N-1)
	LIA <(c8char_N-1)
	CALL c8putchar_BA
	LIA 0x0e
	CALL c8digitaddr
	CALL c8putchar
	LIB >(c8char_W-1)
	LIA <(c8char_W-1)
	CALL c8putchar_BA
	RTN

	;; -----------------------------------------------
	;; Clears the full screen (cls_full) or only
	;; the c8-part of the screen (cls_c8)
	;; -----------------------------------------------
cls_full:
	LIDP VRAM_L1C3
	CALL display_clr_vram
	LIDP VRAM_L1C4
	CALL display_clr_vram
	LIDP VRAM_L1C5
	CALL display_clr_vram
cls_c8:
	LIDP VRAM_L1C1
	CALL display_clr_vram
	LIDP VRAM_L1C2
	CALL display_clr_vram
	LIDP VRAM_L1C3
	LII 4-1
	CALL display_clr_vram_part
	RTN

	;; -----------------------------------------------
	;; Calculate the sprite location of a digit
	;; Used Registers: A,B,X,C,Z,P
	;; -----------------------------------------------
c8digitaddr:
	PUSH
	LP REG_XH
	LIA >(c8font-1)
	EXAM
	LP REG_XL
	LIA <(c8font-1)
	EXAM
	POP
	PUSH
	RC
	SL
	SL
	LP REG_B
	EXAM								; B = 4*A
	POP
	ADM									; B  = 4*A+A = 5*A
	RA									; BA = Offset
	EXAM
	LP REG_XL
	ADB									; X += BA
	RTN

	;; -----------------------------------------------
toggle_snd_stat:
	LIDP c8snd_stat
	LDD
	TSIA 0x20
	JRZP toggle_snd_on
	ANIA 0xdf
	JRP toggle_snd_cont
toggle_snd_on:
	ORIA 0x20
toggle_snd_cont:
	STD
	;; -----------------------------------------------
print_snd_stat:
	; widen screen bounds
	LIA 149
	SET_MAX_GCUR_X
	LIDP VRAM_L1C5						; Clear last display block of first row
	CALL display_clr_vram
	LIA 1
	LIDP display_gcur_y
	STD
	LIA 120
	LIDP display_gcur_x
	STD
	LIDP c8snd_stat
	LDD
	TSIA 0x20
	JRZP c80101
	LIB >(c8char_N-1)
	LIA <(c8char_N-1)
	CALL c8putchar_BA
	JRP c80103
c80101:
	LIA 1
	PUSH
c80102:
	LIA 0x0f
	CALL c8digitaddr
	CALL c8putchar
	LOOP c80102						; LOOP saves 3 bytes
c80103:
	; narrow screen bounds
	LIA 63
	SET_MAX_GCUR_X
	RTN

c8rnd_data:
	.db 0x00							; random number generator data

	;; -----------------------------------------------
	;; 8 bit random number generator. See
	;; https://ygg-it.tripod.com/id28.html
	;; Used Registers: A,B,J,P,DP,C,Z
	;; -----------------------------------------------
c8_rnd:
	LIDP c8rnd_data
	LDD
	LP REG_B
	EXAM								; B = seed
	LDM
	SL
	SL
	SL
	ANIA 0xf8							; A = seed << 3
	CALL c8_xor
	LDM
	RC
	SR									; A = A >> 1	
	CALL c8_xor
	LDM
	SWP
	SL
	ANIA 0xe0							; A = A << 5
	CALL c8_xor
	EXAM								; A = new seed
	STD	
	RTN

	;; -----------------------------------------------
	;; 8 ticks of the 2 msec timer should decrease
	;; the chip8 timers 1 time. For sample code see
	;; digitaluhr_v2.asm
	;; Cycles: min 15 (no internal timer overflow)
	;;         max 68 (int. timer ovl., del .timer
    ;;          != 0, snd. timer = 1)
	;; -----------------------------------------------
c8_dec_timers_kbd::
c8_dec_timers:
	TEST TEST_CNT_2				; 4		; Test 2 ms timer
	JRZP c80203					; 7 4
c8_dec_timers_notest:
	LP C8INT_TIMER				;   2
	ADIM 1						;   4
	ANIM 0x07					;   4	; Count 0..7
	JRNZP c80203				;   7 4
c8_dec_timers_doit:
	; dec delay timer
	LP C8DEL_TIMER				;     2
	TSIM 0xff					;     4
	JRZP c80201					;     7 4
	SBIM 1						;       4
c80201:
	; dec sound timer
	LP C8SND_TIMER				;     2
	TSIM 0xff					;     4
	JRZP c80203					;     7 4
	SBIM 1						;       4
	JRNZP c80203				;       7 4
	SND_OFF						;         10
c80203:
	RTN							; 4

c8_dec_timers_disp::
	CPIA 0						; 4
	JRZM c8_dec_timers			; 4 7
	LP C8INT_TIMER				; 2
	EXAM						; 3
	PUSH						; 3		; Push prev. value of internal counter 
	EXAM						; 3
	ADM							; 3		; Increase internal counter by the amount of missed timer ticks
	LDM							; 2		; A=internal counter
	ANIA 0xf8					; 4		; Reset the last three bits
	LP REG_J					; 2
	EXAM						; 3		; J=5 bits of internal counter
	TEST TEST_CNT_2				; 4		; Test 2 ms timer to clear it
	POP							; 2		; Fetch prev. value of internal counter from stack 
	ANIA 0xf8					; 4		; Reset the last three bits
	CPMA						; 3
	LIJ 1						; 4		; Messing round with J is dangerous ...
	JRNZM c8_dec_timers_doit	; 4 7	; If compare is non-zero, decrease delay- and sound timer
	RTN 						; 4

c8minimal_prog:
;	.db 0x12, 0x00						; jp 0x200 (chip-8 code)
	.db 0xf0, 0x0a						; ld v0, k (chip-8 code)
	.db 0x00, 0xfd						; exit (chip-8 code)
	.db 0xff							; Indicator for start of BASIC text
	.db 0xff							; Indicator for end of BASIC text
c8minprog_end:

c8bounds:
	LIA 0xff
	LIDP VRAM_L1C3+4
	STD_HIMEM
	LIDL <(VRAM_L2C3+4)
	STD_HIMEM
	LIDL <(VRAM_L3C3+4)
	STD_HIMEM
	LIDL <(VRAM_L4C3+4)
	STD_HIMEM
	RTN

c8snd_stat:								; sound and pitch status - 0 or 0x10 if sound is off
	.db 0x20

	;; Characters needed by status text at the right half of the display 
c8char_N:
	C8FONT_CHAR_N						; N
c8char_P:
	C8FONT_CHAR_P						; P
c8char_U:
	C8FONT_CHAR_U						; U
c8char_W:
	C8FONT_CHAR_W						; W

