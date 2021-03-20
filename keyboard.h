	;;***************************************************************************
	;;*                                                                         *
	;;*   This program is free software; you can redistribute it and/or modify  *
	;;*   it under the terms of the GNU General Public License as published by  *
	;;*   the Free Software Foundation; either version 2 of the License, or     *
	;;*   (at your option) any later version.                                   *
	;;*                                                                         *
	;;***************************************************************************

.ifndef keyboard_h
.define keyboard_h

.include "target.h"
.include "regs.h"

.globl keyboard_raw_inkey
.globl keyboard_callback
.globl keyboard_testKP

; Keycodes

.if __PC_1350__

; Port IA matrix scan code offset
PORT_A_OFFS = 0x00
; Port K matrix scan code offset
KEYPORT_OFFS = 0x15

KEY_A	       =   0x1d					; 29
KEY_B	       =   0x3a					; 58
KEY_C	       =   0x2c					; 44
KEY_D	       =   0x2b					; 43
KEY_E	       =   0x2a					; 42
KEY_F	       =   0x32					; 50
KEY_G	       =   0x39					; 57
KEY_H	       =   0x01					;  1
KEY_I	       =   0x0b					; 11
KEY_J	       =   0x07					;  7
KEY_K	       =   0x0c					; 12
KEY_L	       =   0x10					; 16
KEY_M	       =   0x08					;  8
KEY_N	       =   0x02					;  2
KEY_O	       =   0x0f					; 15
KEY_P	       =   0x12					; 18
KEY_Q	       =   0x1c					; 28
KEY_R	       =   0x31					; 49
KEY_S	       =   0x24					; 36
KEY_T	       =   0x38					; 56
KEY_U	       =   0x06					;  6
KEY_V	       =   0x33					; 51
KEY_W	       =   0x23					; 35
KEY_X	       =   0x25					; 37
KEY_Y	       =   0x00					;  0
KEY_Z	       =   0x1e					; 30

KEY_1	       =   0x35					; 53
KEY_2	       =   0x2e					; 46
KEY_3          =   0x27					; 39
KEY_4          =   0x36					; 54
KEY_5          =   0x2f					; 47
KEY_6          =   0x28					; 40
KEY_7          =   0x37					; 55
KEY_8	       =   0x30					; 48
KEY_9	       =   0x29					; 41
KEY_0          =   0x34					; 52

KEY_MODE       =   0x09					;  9
KEY_SPACE      =   0x0d					; 13
KEY_CLS        =   0x0e					; 14
KEY_ENTER      =   0x11					; 17

KEY_SHIFT      =   0x15					; 21
KEY_DEF        =   0x16					; 22
KEY_SML        =   0x17					; 23

KEY_DOWN       =   0x3d					; 61
KEY_UP         =   0x3e					; 62
KEY_LEFT       =   0x3c					; 60
KEY_RIGHT      =   0x3b					; 59
KEY_DEL        =   0x03					;  3
KEY_INS        =   0x04					;  4

KEY_COMMA      =   0x18					; 24, the , key
KEY_PERIOD     =   0x2d					; 45, the . key

KEY_EQUAL      =   0x13					; 19, the = key
KEY_MINUS      =   0x1f					; 31
KEY_PLUS       =   0x26					; 38
KEY_ASTERISK   =   0x20					; 32, the * key
KEY_SLASH      =   0x21					; 33, the / key
KEY_PARENLEFT  =   0x22					; 34, the ( key
KEY_PARENRIGHT =   0x1b					; 27, the ) key

KEY_BREAK      =   0x3f					; 63

.endif

.if __PC_1360__

; Port IA matrix scan code offset
PORT_A_OFFS = 0x00
; Port K matrix scan code offset
KEYPORT_OFFS = 0x15

KEY_A	       =   0x1d					; 29
KEY_B	       =   0x3a					; 58
KEY_C	       =   0x2c					; 44
KEY_D	       =   0x2b					; 43
KEY_E	       =   0x2a					; 42
KEY_F	       =   0x32					; 50
KEY_G	       =   0x39					; 57
KEY_H	       =   0x40					; 64
KEY_I	       =   0x06					;  6
KEY_J	       =   0x01					;  1
KEY_K	       =   0x07					;  7
KEY_L	       =   0x0c					; 12
KEY_M	       =   0x02					;  2
KEY_N	       =   0x41					; 65
KEY_O	       =   0x0b					; 11
KEY_P	       =   0x0f					; 15
KEY_Q	       =   0x1c					; 28
KEY_R	       =   0x31					; 49
KEY_S	       =   0x24					; 36
KEY_T	       =   0x38					; 56
KEY_U	       =   0x00					;  0
KEY_V	       =   0x33					; 51
KEY_W	       =   0x23					; 35
KEY_X	       =   0x25					; 37
KEY_Y	       =   0x3f					; 63
KEY_Z	       =   0x1e					; 30

KEY_1	       =   0x35					; 53
KEY_2	       =   0x2e					; 46
KEY_3          =   0x27					; 39
KEY_4          =   0x36					; 54
KEY_5          =   0x2f					; 47
KEY_6          =   0x28					; 40
KEY_7          =   0x37					; 55
KEY_8	       =   0x30					; 48
KEY_9	       =   0x29					; 41
KEY_0          =   0x34					; 52

KEY_MODE       =   0x03					;  3
KEY_SPACE      =   0x08					;  8
KEY_CLS        =   0x09					;  9
KEY_ENTER      =   0x0d					; 13

KEY_SHIFT      =   0x15					; 21
KEY_DEF        =   0x16					; 22
KEY_SML        =   0x17					; 23

KEY_DOWN       =   0x3d					; 61
KEY_UP         =   0x3e					; 62
KEY_LEFT       =   0x3c					; 60
KEY_RIGHT      =   0x3b					; 59
KEY_DEL        =   0x42					; 66
KEY_INS        =   0x43					; 67

KEY_COMMA      =   0x18					; 24, the , key
KEY_PERIOD     =   0x2d					; 45, the . key

KEY_EQUAL      =   0x10					; 16, the = key
KEY_MINUS      =   0x1f					; 31
KEY_PLUS       =   0x26					; 38
KEY_ASTERISK   =   0x20					; 32, the * key
KEY_SLASH      =   0x21					; 33, the / key
KEY_PARENLEFT  =   0x22					; 34, the ( key
KEY_PARENRIGHT =   0x1b					; 27, the ) key

KEY_BREAK      =   0x47					; 71

.endif

.if __PC_2500__

; Port IA matrix scan code offset
PORT_A_OFFS = 0x38
; Port K matrix scan code offset
KEYPORT_OFFS = 0x00

KEY_A	       =   0x02					;  2
KEY_B	       =   0x1f					; 31
KEY_C	       =   0x11					; 17
KEY_D	       =   0x10					; 16
KEY_E	       =   0x0f					; 15
KEY_F	       =   0x17					; 23
KEY_G	       =   0x1e					; 30
KEY_H	       =   0x25					; 37
KEY_I	       =   0x32					; 50
KEY_J	       =   0x2c					; 44
KEY_K	       =   0x33					; 51
KEY_L	       =   0x3a					; 58
KEY_M	       =   0x2d					; 45
KEY_N	       =   0x26					; 38
KEY_O	       =   0x39					; 57
KEY_P	       =   0x3f					; 63
KEY_Q	       =   0x01					;  1
KEY_R	       =   0x16					; 22
KEY_S	       =   0x09					;  9
KEY_T	       =   0x1d					; 29
KEY_U	       =   0x2b					; 43
KEY_V	       =   0x18					; 24
KEY_W	       =   0x08					;  8
KEY_X	       =   0x0a					; 10
KEY_Y	       =   0x24					; 36
KEY_Z	       =   0x03					;  3

KEY_1	       =   0x00					;  0
KEY_2	       =   0x07					;  7
KEY_3          =   0x0e					; 14
KEY_4          =   0x15					; 21
KEY_5          =   0x1c					; 28
KEY_6          =   0x23					; 35
KEY_7          =   0x2a					; 42
KEY_8	       =   0x31					; 49
KEY_9	       =   0x38					; 56
KEY_0          =   0x3e					; 62

KEY_MODE       =   0x3d					; 61
KEY_SPACE      =   0x04					;  4
KEY_CLS        =   0x37					; 55
KEY_ENTER      =   0x14					; 20

KEY_DEF        =   0x4c					; 76
KEY_CAPS       =   0x06					;  6

KEY_DOWN       =   0x42					; 66
KEY_UP         =   0x46					; 70
KEY_LEFT       =   0x4b					; 75
KEY_RIGHT      =   0x49					; 73
KEY_DEL        =   0x29					; 41, backspace
KEY_INS        =   0x30					; 48
KEY_PEN        =   0x3c					; 60

KEY_COMMA      =   0x34					; 52, the , key
KEY_PERIOD     =   0x3b					; 59, the . key
KEY_SEMICOLON  =   0x40					; 64
KEY_DEAD_ACUT  =   0x4a					; 74, the ´ key

KEY_EQUAL      =   0x47					; 71, the = key
KEY_MINUS      =   0x43					; 67
KEY_PLUS       =   0x12					; 18, on num. key pad
KEY_ASTERISK   =   0x0b					; 11, the * key, on num. key pad
KEY_SLASH      =   0x44					; 68, the / key

; Num. pad keys
KEY_NUM_1	   =   0x20					; 32
KEY_NUM_2	   =   0x21					; 33
KEY_NUM_3      =   0x0c					; 12
KEY_NUM_4      =   0x27					; 39
KEY_NUM_5      =   0x28					; 40
KEY_NUM_6      =   0x05					;  5
KEY_NUM_7      =   0x2e					; 46
KEY_NUM_8	   =   0x2f					; 47
KEY_NUM_9	   =   0x36					; 54
KEY_NUM_0      =   0x19					; 25
KEY_NUM_PERIOD =   0x1a					; 26, the . key
KEY_NUM_MINUS  =   0x13					; 19
KEY_NUM_SLASH  =   0x35					; 53, the / key

KEY_BREAK      =   0x4d					; 77 

.endif

KEY_MULTIPLE = KEY_BREAK+1				; Keycode returned when multiple keys are pressed

.if __PC_1350__
KEY_PORT = 0x7e00
SCANLINES_KB = 6
SCANLINES_ON = 0x3f
.endif

.if __PC_1360__
KEY_PORT = 0x3e00
SCANLINES_KB = 7
SCANLINES_ON = 0x08
.endif

.if __PC_2500__
KEY_PORT_1 = 0x7a00
KEY_PORT_2 = 0x7b00
.endif

	;; -----------------------------------------------
	;; Modifies the jump address in the dummy
	;; callback function to define a customized
	;; callback function. This may be used to update
	;; timer counters etc. while long running key-
	;; board functions
	;; -----------------------------------------------
.macro SET_KBD_CALLBACK arg_addr
	LIA >(arg_addr)
	LIDP keyboard_callback+1
	STD
	LIA <(arg_addr)
	LIDP keyboard_callback+2
	STD
.endm

	;; -----------------------------------------------
	;; Waits for press and release of the break key
	;; Used registers and flags: Z
	;; 8 bytes
	;; -----------------------------------------------
.macro WAIT_BREAK
;lb1
	TEST TEST_BRK				; Test break key
	.db 0x39, 0x03				; JRZM lb1	; If not pressed, loop
;lb2
	TEST TEST_BRK				; Test break key
	.db 0x29, 0x03				; JRNZM lb2	; If still pressed, loop
.endm

	;; -----------------------------------------------
	;; Enable power saving while wait for key press
	;; See keyboard handling of the monitor program
	;; in http://lib.berwanger.org/pc1360/index.php
	;; Used registers and flags: Z
	;; 12 bytes
	;; -----------------------------------------------
.macro KBD_IDLE
	LIP PORT_C					; Address port C
	ORIM 0x04					; Timeout 512 ms
;lb1:
	OUTC						; and write to port
	TEST TEST_CNT_512			; Timeout ?
	.db 0x29, 0x04				; JRNZM lb1	; yes! -> go on
	ANIM 0xfb					; Reset timeout
	OUTC
.endm

	;; -----------------------------------------------
	;; Used registers and flags: DP
	;; 10 bytes on PC-2500, 5 on other models
	;; -----------------------------------------------
.if __PC_2500__

.macro KBD_SET_KB
	LIDP KEY_PORT_1
	ORID 0x0f
	LIDP KEY_PORT_2
	ORID 0x0f
.endm

.else

.macro KBD_SET_KB
	LIDP KEY_PORT
	ORID SCANLINES_ON
.endm

.endif

.endif
