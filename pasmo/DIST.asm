; generated from src/DIST.Z80 by pasmo/m80topasmo.py -- do not edit
;
;BBC BASIC (Z80) - CP/M VERSION 2.20 & 3.00
;(C) COPYRIGHT R.T.RUSSELL, 1982-2024.
;ALL RIGHTS RESERVED.
;
;THIS PROGRAM ALLOWS THE USER TO ADAPT BBC BASIC TO THE
;PARTICULAR CHARACTERISTICS OF HIS SYSTEM HARDWARE ETC.
;
;THE PROGRAM RESIDES AT 100H FOR EASE OF LOADING.
;*** IT MUST NOT EXCEED 256 BYTES IN TOTAL LENGTH ***
;
;PLEASE NOTE THAT A Z80 PROCESSOR AND CP/M VERSION 2.2
;OR LATER ARE REQUIRED.
;
;R.T.RUSSELL, 11-03-1984, 03-05-1989, 12-05-2024
;
DIST_CPM:	EQU	5
DIST_COLD:	EQU	200H
;
;
	ORG	100H
;
;JUMP TABLE - BASIC makes calls to hardware-dependent
;features via this table:
;
	JP	DIST_INIT
CLRSCN:	JP	DIST_CLS			;CLEAR SCREEN
PUTCSR:	JP	DIST_PCSR			;SET CURSOR POSN.
GETCSR:	JP	DIST_GCSR			;READ CURSOR POSN.
PUTIME:	JP	DIST_PTIME			;SET ELAPSED TIME
GETIME:	JP	DIST_GTIME			;READ ELAPSED TIME
GETKEY:	JP	DIST_INKEY			;READ KEY (TIME LIMIT)
BYE:	JP	DIST_REBOOT			;RETURN TO CP/M
;
;BDOS	- Save the IX and IY registers and before performing a
;	  CP/M function call.
;
DIST_BDOS:	PUSH	IX
	PUSH	IY
	CALL	DIST_CPM
	POP	IY
	POP	IX
	RET
;
;INIT	- Perform hardware initialisation (if any).
;
DIST_INIT:	LD	A,2
	INC	A
	LD	DE,DIST_NOTZ80
	JP	PE,DIST_FAIL
	LD	C,12
	CALL	DIST_BDOS
	OR	A
	LD	DE,DIST_NOTV2
	JP	NZ,DIST_COLD
DIST_FAIL:	LD	C,9
	CALL	DIST_BDOS
	RST	0
;
DIST_NOTZ80:	DEFB	'Not a Z80$'
DIST_NOTV2:	DEFB	'Not CP/M 2$'
;
;REBOOT	- Switch off interrupts and return to CP/M
;
DIST_REBOOT:	RST	0
;
;GTIME	- Read elapsed-time clock.
;  	  Outputs: DEHL = elapsed time (centiseconds)
; 	  Destroys: A,D,E,H,L,F
;
DIST_GTIME:	PUSH	BC
	CALL	DIST_TICKS
	LD	BC,(DIST_OFFLO)
	ADD	HL,BC
	EX	DE,HL
	LD	BC,(DIST_OFFHI)
	ADC	HL,BC
	EX	DE,HL
	POP	BC
	RET
;
;PTIME	- Load elapsed-time clock.
;   	  Inputs: DEHL = time to load (centiseconds)
; 	  Destroys: A,D,E,H,L,F
;
DIST_PTIME:	PUSH	BC
	PUSH	DE
	PUSH	HL
	CALL	DIST_TICKS
	LD	B,H
	LD	C,L
	POP	HL
	OR	A
	SBC	HL,BC
	LD	(DIST_OFFLO),HL
	LD	B,D
	LD	C,E
	POP	HL
	SBC	HL,BC
	LD	(DIST_OFFHI),HL
	POP	BC
	RET
;
; Get OS elapsed-time clock
;  Outputs: DEHL = time (centiseconds)
; Destroys: A,B,C,D,E,H,L,F
;
DIST_TICKS:	LD	C,248			;RunCPM-specific function call
	CALL	DIST_BDOS
	PUSH	DE
	EX	DE,HL
	OR	A
	SBC	HL,HL
	LD	BC,-5
	LD	A,32
DIST_DIV0:	ADD	HL,BC
	JR	C,DIST_DIV1
	SBC	HL,BC
DIST_DIV1:	RL	E
	RL	D
	EX	(SP),HL
	RL	L
	RL	H
	EX	(SP),HL
	ADC	HL,HL
	DEC	A
	JR	NZ,DIST_DIV0
	EX	DE,HL
	POP	DE
	RET
;
;INKEY	- Sample keyboard with specified wait.
;   	  Inputs: HL = Time to wait (centiseconds)
;  	  Outputs: Carry reset indicates time-out.
;                  If carry set, A = character typed.
; 	  Destroys: A,D,E,H,L,F
;
DIST_INKEY:	PUSH	BC
	PUSH	HL
	CALL	DIST_TICKS
	POP	DE
	ADD	HL,DE
DIST_WAIT:	PUSH	HL
	LD	C,6
	LD	E,0FFH
	CALL	DIST_BDOS
	POP	HL
	OR	A
	SCF
	JR	NZ,DIST_INKEY1
	PUSH	HL
	CALL	DIST_TICKS
	POP	DE
	SBC	HL,DE
	EX	DE,HL
	JR	C,DIST_WAIT	
DIST_INKEY1:	POP	BC
	RET
;
;CLS	- Clear screen.
;	  (Customise to suit your VDU)
; 	  Destroys: A,D,E,H,L,F
;
DIST_CLS:	RET
;
;PCSR	- Move cursor to specified position.
;   	  Inputs: DE = horizontal position (LHS=0)
;                 HL = vertical position (TOP=0)
; 	  Destroys: A,D,E,H,L,F
;
DIST_PCSR:	RET
;
;GCSR	- Return cursor coordinates.
;   	  Outputs:  DE = X coordinate (POS)
;                   HL = Y coordinate (VPOS)
;  	  Destroys: A,D,E,H,L,F
;
DIST_GCSR:	LD	DE,0
	LD	HL,0
	RET
;
;COUT - Output a character to the console
;   Inputs: A = character
; Destroys: A,F
;
DIST_COUT:	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	E,A
	LD	C,2
	CALL	DIST_BDOS
	POP	HL
	POP	DE
	POP	BC
	RET
;
	IF	$ GT 1F0H
	ENDIF
;
	ORG	1F0H
;
DIST_OFFLO:	DEFW	0			;TIME OFFSET LO
DIST_OFFHI:	DEFW	0			;TIME OFFSET HI
	DEFB	80			;WIDTH
	DEFB	'G' AND 1FH		;CURSOR UP
	DEFB	'O' AND 1FH		;CURSOR DOWN
	DEFB	'F' AND 1FH		;START OF LINE
	DEFB	'N' AND 1FH		;END OF LINE
	DEFB	'X' AND 1FH		;DELETE TO END OF LINE
	DEFB	08H			;BACKSPACE & DELETE
	DEFB	'U' AND 1FH		;DEL TO START OF LINE
	DEFB	'J' AND 1FH		;CURSOR LEFT
	DEFB	'L' AND 1FH		;CURSOR RIGHT
	DEFB	'R' AND 1FH		;DELETE CHARACTER
	DEFB	'Q' AND 1FH		;INS/OVR TOGGLE
;
DIST_FIN:

