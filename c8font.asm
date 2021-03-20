	;;***************************************************************************
	;;*                                                                         *
	;;*   This program is free software; you can redistribute it and/or modify  *
	;;*   it under the terms of the GNU General Public License as published by  *
	;;*   the Free Software Foundation; either version 2 of the License, or     *
	;;*   (at your option) any later version.                                   *
	;;*                                                                         *
	;;***************************************************************************

.area chip8 (REL)

c8font::
	.db 0b11110000						; 0
	.db 0b10010000
	.db 0b10010000
	.db 0b10010000
	.db 0b11110000

	.db 0b00100000						; 1
	.db 0b01100000
	.db 0b00100000
	.db 0b00100000
	.db 0b01110000

	.db 0b11110000						; 2
	.db 0b00010000
	.db 0b11110000
	.db 0b10000000
	.db 0b11110000

	.db 0b11110000						; 3
	.db 0b00010000
	.db 0b11110000
	.db 0b00010000
	.db 0b11110000

	.db 0b10010000						; 4
	.db 0b10010000
	.db 0b11110000
	.db 0b00010000
	.db 0b00010000

	.db 0b11110000						; 5
	.db 0b10000000
	.db 0b11110000
	.db 0b00010000
	.db 0b11110000

	.db 0b11110000						; 6
	.db 0b10000000
	.db 0b11110000
	.db 0b10010000
	.db 0b11110000

	.db 0b11110000						; 7
	.db 0b00010000
	.db 0b00100000
	.db 0b01000000
	.db 0b01000000

	.db 0b11110000						; 8
	.db 0b10010000
	.db 0b11110000
	.db 0b10010000
	.db 0b11110000

	.db 0b11110000						; 9
	.db 0b10010000
	.db 0b11110000
	.db 0b00010000
	.db 0b11110000

	.db 0b11110000						; A
	.db 0b10010000
	.db 0b11110000
	.db 0b10010000
	.db 0b10010000

	.db 0b11100000						; B
	.db 0b10010000
	.db 0b11100000
	.db 0b10010000
	.db 0b11100000

	.db 0b11110000						; C
	.db 0b10000000
	.db 0b10000000
	.db 0b10000000
	.db 0b11110000

	.db 0b11100000						; D
	.db 0b10010000
	.db 0b10010000
	.db 0b10010000
	.db 0b11100000

	.db 0b11110000						; E
	.db 0b10000000
	.db 0b11110000
	.db 0b10000000
	.db 0b11110000

	.db 0b11110000						; F
	.db 0b10000000
	.db 0b11110000
	.db 0b10000000
	.db 0b10000000

