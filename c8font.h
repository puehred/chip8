	;;***************************************************************************
	;;*                                                                         *
	;;*   This program is free software; you can redistribute it and/or modify  *
	;;*   it under the terms of the GNU General Public License as published by  *
	;;*   the Free Software Foundation; either version 2 of the License, or     *
	;;*   (at your option) any later version.                                   *
	;;*                                                                         *
	;;***************************************************************************

	;; -----------------------------------------------
	;; CHIP-8 font - 80 bytes
	;; file     : c8font.h
	;; author   : puehringer edgar
	;; date     : 14.05.2020                 
	;; assembler: as61860                    
	;; -----------------------------------------------

.ifndef c8font_h
.define c8font_h

.globl c8font

.macro C8FONT_CHAR_N
	.db 0b10010000						; N
	.db 0b10010000
	.db 0b11010000
	.db 0b10110000
	.db 0b10010000
.endm

.macro C8FONT_CHAR_P
	.db 0b11100000						; P
	.db 0b10010000
	.db 0b11100000
	.db 0b10000000
	.db 0b10000000
.endm

.macro C8FONT_CHAR_U
	.db 0b10010000						; U
	.db 0b10010000
	.db 0b10010000
	.db 0b10010000
	.db 0b11110000
.endm

.macro C8FONT_CHAR_W
	.db 0b10010000						; W
	.db 0b10010000
	.db 0b11010000
	.db 0b11010000
	.db 0b10100000
.endm

.endif
