; generated from src/AMOS.Z80 by pasmo/m80topasmo.py -- do not edit
;
;PATCH FOR BBC BASIC TO CP/M 2.2 & 3.0
;* ACORN COMPUTERS Z80 TUBE VERSION  *
;(C) COPYRIGHT R.T.RUSSELL, 08-05-1984
;VERSION 5.0, 14-06-2024
;
;
;
;
;OSSAVE - Save an area of memory to a file.
;   Inputs: HL addresses filename (term CR)
;           DE = start address of data to save
;           BC = length of data to save (bytes)
; Destroys: A,B,C,D,E,H,L,F
;
AMOS_STSAVE:	CALL	AMOS_SAVLOD			;*SAVE
	JP	C,AMOS_HUH			;"Bad command"
	PUSH	HL
	JR	AMOS_OSS1
;
OSSAVE:	PUSH	BC			;SAVE
	CALL	AMOS_SETUP0
AMOS_OSS1:	EX	DE,HL
	CALL	AMOS_CREATE
	JR	NZ,AMOS_SAVE
	LD	A,190
	CALL	EXTERR
	DEFM	'Directory full'
	DEFB	0
AMOS_SAVE:	CALL	AMOS_WRITE
	ADD	HL,BC
	EX	(SP),HL
	SBC	HL,BC
	EX	(SP),HL
	JR	Z,AMOS_SAVE1
	JR	NC,AMOS_SAVE
AMOS_SAVE1:	POP	BC
AMOS_CLOSE:	LD	A,16
	CALL	AMOS_BDOS1
	INC	A
	RET	NZ
	LD	A,200
	CALL	EXTERR
	DEFM	'Close error'
	DEFB	0
;
;OSSHUT - Close disk file(s).
;   Inputs: E = file channel
;           If E=0 all files are closed
; Destroys: A,B,C,D,E,H,L,F
;
OSSHUT:	LD	A,E
	OR	A
	JR	NZ,AMOS_SHUTIT
AMOS_SHUT0:	INC	E
	BIT	3,E
	RET	NZ
	PUSH	DE
	CALL	AMOS_SHUT1
	POP	DE
	JR	AMOS_SHUT0
;
AMOS_SHUTIT:	CALL	AMOS_FIND1
	JR	NZ,AMOS_SHUT2
	JP	AMOS_CHANER
;
AMOS_SHUT1:	CALL	AMOS_FIND1
	RET	Z
AMOS_SHUT2:	XOR	A
	LD	(HL),A
	DEC	HL
	LD	(HL),A
	LD	HL,37
	ADD	HL,DE
	BIT	7,(HL)
	INC	HL
	CALL	NZ,AMOS_WRITE
	LD	HL,AMOS_FCBSIZ
	ADD	HL,DE
	LD	BC,(FREE)
	SBC	HL,BC
	JR	NZ,AMOS_CLOSE
	LD	(FREE),DE		;RELEASE SPACE
	JR	AMOS_CLOSE
;
;TYPE - *TYPE command.
;Types file to console output.
;
AMOS_TYPE:	SCF	;*TYPE
	CALL	OSOPEN
	OR	A
	JR	Z,AMOS_NOTFND
	LD	E,A
AMOS_TYPE1:	CALL	TRAP			;IMPORTANT (ACORN)
	CALL	OSBGET
	CALL	OSWRCH
	JR	NC,AMOS_TYPE1
	JR	OSSHUT
;
;OSLOAD - Load an area of memory from a file.
;   Inputs: HL addresses filename (term CR)
;           DE = address at which to load
;           BC = maximum allowed size (bytes)
;  Outputs: Carry reset indicates no room for file.
; Destroys: A,B,C,D,E,H,L,F
;
AMOS_STLOAD:	CALL	AMOS_SAVLOD			;*LOAD
	PUSH	HL
	JR	AMOS_OSL1
;
OSLOAD:	PUSH	BC			;LOAD
	CALL	AMOS_SETUP0
AMOS_OSL1:	EX	DE,HL
	CALL	AMOS_OPEN
	JR	NZ,AMOS_LOAD0
AMOS_NOTFND:	LD	A,214
	CALL	EXTERR
	DEFM	'File not found'
	DEFB	0
AMOS_LOAD:	CALL	AMOS_READ
	JR	NZ,AMOS_LOAD1
	CALL	AMOS_INCSEC
	ADD	HL,BC
AMOS_LOAD0:	EX	(SP),HL
	SBC	HL,BC
	EX	(SP),HL
	JR	NC,AMOS_LOAD
AMOS_LOAD1:	POP	BC
	PUSH	AF
	CALL	AMOS_CLOSE
	POP	AF
	CCF
RESET:	RET
;
;OSOPEN - Open a file for reading or writing.
;   Inputs: HL addresses filename (term CR)
;           Carry set for OPENIN, cleared for OPENOUT.
;  Outputs: A = file channel (=0 if cannot open)
; Destroys: A,B,C,D,E,H,L,F
;
OSOPEN:	PUSH	AF			;SAVE CARRY
	CALL	AMOS_SETUP0
	POP	AF
	CALL	NC,AMOS_CREATE
	CALL	C,AMOS_OPEN
	RET	Z			;ERROR
	LD	B,7			;MAX. NUMBER OF FILES
	LD	HL,AMOS_TABLE+13
AMOS_OPEN1:	LD	A,(HL)
	DEC	HL
	OR	(HL)
	JR	Z,AMOS_OPEN2
	DEC	HL
	DJNZ	AMOS_OPEN1
	LD	A,192
	CALL	EXTERR
	DEFM	'Too many open files'
	DEFB	0
;
AMOS_OPEN2:	LD	DE,(FREE)		;FREE SPACE POINTER
	LD	(HL),E
	INC	HL
	LD	(HL),D
	LD	A,B			;CHANNEL (1-7)
	LD	HL,AMOS_FCBSIZ
	ADD	HL,DE			;RESERVE SPACE
	LD	(FREE),HL
	LD	HL,AMOS_FCB
	PUSH	DE
	LD	BC,36
	LDIR	;COPY FCB
	EX	DE,HL
	INC	HL
	LD	(HL),C			;CLEAR PTR
	INC	HL
	POP	DE
	LD	B,A
	CALL	AMOS_RDF			;READ OR FILL
	LD	A,B
	JP	CHECK
;
;OSBPUT - Write a byte to a random disk file.
;   Inputs: E = file channel
;           A = byte to write
; Destroys: A,B,C,F
;
OSBPUT:	PUSH	DE
	PUSH	HL
	LD	B,A
	CALL	AMOS_FIND
	LD	A,B
	LD	B,0
	DEC	HL
	LD	(HL),B			;CLEAR EOF
	INC	HL
	LD	C,(HL)
	RES	7,C
	SET	7,(HL)
	INC	(HL)
	INC	HL
	PUSH	HL
	ADD	HL,BC
	LD	(HL),A
	POP	HL
	CALL	Z,AMOS_WRRDF			;WRITE THEN READ/FILL
	POP	HL
	POP	DE
	RET
;
;OSBGET - Read a byte from a random disk file.
;   Inputs: E = file channel
;  Outputs: A = byte read
;           Carry set if LAST BYTE of file
; Destroys: A,B,C,F
;
OSBGET:	PUSH	DE
	PUSH	HL
	CALL	AMOS_FIND
	LD	C,(HL)
	RES	7,C
	INC	(HL)
	INC	HL
	PUSH	HL
	LD	B,0
	ADD	HL,BC
	LD	B,(HL)
	POP	HL
	CALL	PE,AMOS_INCRDF		;INC SECTOR THEN READ
	CALL	Z,AMOS_WRRDF			;WRITE THEN READ/FILL
	LD	A,B
	POP	HL
	POP	DE
	RET
;
;OSSTAT - Read file status.
;   Inputs: E = file channel
;  Outputs: Z flag set - EOF
;           (If Z then A=0)
;           DE = address of file block.
; Destroys: A,D,E,H,L,F
;
OSSTAT:	CALL	AMOS_FIND
	DEC	HL
	LD	A,(HL)
	INC	A
	RET
;
;GETEXT - Find file size.
;   Inputs: E = file channel
;  Outputs: DEHL = file size (0-&800000)
; Destroys: A,B,C,D,E,H,L,F
;
GETEXT:	CALL	AMOS_FIND
	EX	DE,HL
	LD	DE,AMOS_FCB
	LD	BC,36
	PUSH	DE
	LDIR	;COPY FCB
	EX	DE,HL
	EX	(SP),HL
	EX	DE,HL
	LD	A,35
	CALL	AMOS_BDOS1			;COMPUTE SIZE
	POP	HL
	XOR	A
	JR	AMOS_GETPT1
;
;GETPTR - Return file pointer.
;   Inputs: E = file channel
;  Outputs: DEHL = pointer (0-&7FFFFF)
; Destroys: A,B,C,D,E,H,L,F
;
GETPTR:	CALL	AMOS_FIND
	LD	A,(HL)
	ADD	A,A
	DEC	HL
AMOS_GETPT1:	DEC	HL
	LD	D,(HL)
	DEC	HL
	LD	E,(HL)
	DEC	HL
	LD	H,(HL)
	LD	L,A
	SRL	D
	RR	E
	RR	H
	RR	L
	RET
;
;PUTPTR - Update file pointer.
;   Inputs: A = file channel
;           DEHL = new pointer (0-&7FFFFF)
; Destroys: A,B,C,D,E,H,L,F
;
PUTPTR:	LD	D,L
	ADD	HL,HL
	RL	E
	LD	B,E
	LD	C,H
	LD	E,A			;CHANNEL
	PUSH	DE
	CALL	AMOS_FIND
	POP	AF
	AND	7FH
	BIT	7,(HL)			;PENDING WRITE?
	JR	Z,AMOS_PUTPT1
	OR	80H
AMOS_PUTPT1:	LD	(HL),A
	PUSH	DE
	PUSH	HL
	DEC	HL
	DEC	HL
	DEC	HL
	LD	D,(HL)
	DEC	HL
	LD	E,(HL)
	EX	DE,HL
	OR	A
	SBC	HL,BC
	POP	HL
	POP	DE
	RET	Z
	INC	HL
	OR	A
	CALL	M,AMOS_WRITE
	PUSH	HL
	DEC	HL
	DEC	HL
	DEC	HL
	LD	(HL),0
	DEC	HL
	LD	(HL),B
	DEC	HL
	LD	(HL),C			;NEW RECORD NO.
	POP	HL
	JR	AMOS_RDF
;
;WRRDF - Write, read; if EOF fill with zeroes.
;RDF - Read; if EOF fill with zeroes.
;   Inputs: DE address FCB.
;           HL addresses data buffer.
;  Outputs: A=0, Z-flag set.
;           Carry set if fill done (EOF)
; Destroys: A,H,L,F
;
AMOS_WRRDF:	CALL	AMOS_WRITE
AMOS_RDF:	CALL	AMOS_READ
	DEC	HL
	RES	7,(HL)
	DEC	HL
	LD	(HL),A			;CLEAR EOF FLAG
	RET	Z
	LD	(HL),-1			;SET EOF FLAG
	INC	HL
	INC	HL
	PUSH	BC
	XOR	A
	LD	B,128
AMOS_FILL:	LD	(HL),A
	INC	HL
	DJNZ	AMOS_FILL
	POP	BC
	SCF
	RET
;
;INCRDF - Increment record, read; if EOF fill.
;   Inputs: DE addresses FCB.
;           HL addresses data buffer.
;  Outputs: A=1, Z-flag reset.
;           Carry set if fill done (EOF)
; Destroys: A,H,L,F
;
AMOS_INCRDF:	CALL	AMOS_INCSEC
	CALL	AMOS_RDF
	INC	A
	RET
;
;READ - Read a record from a disk file.
;   Inputs: DE addresses FCB.
;           HL = address to store data.
;  Outputs: A<>0 & Z-flag reset indicates EOF.
;           Carry = 0
; Destroys: A,F
;
;BDOS1 - CP/M BDOS call.
;   Inputs: A = function number
;          DE = parameter
;  Outputs: AF = result (carry=0)
; Destroys: A,F
;
AMOS_READ:	CALL	AMOS_SETDMA
	LD	A,33
AMOS_BDOS1:	CALL	AMOS_BDOS0
	JR	NZ,AMOS_CPMERR
	OR	A
	RET
AMOS_CPMERR:	LD	A,255
	CALL	EXTERR
	DEFM	'CP/M Error'
	DEFB	0
;
AMOS_BDOS0:	PUSH	BC
	PUSH	DE
	PUSH	HL
	PUSH	IX
	PUSH	IY
	LD	C,A
	CALL	AMOS_BDOS
	INC	H
	DEC	H
	POP	IY
	POP	IX
	POP	HL
	POP	DE
	POP	BC
	RET
;
;WRITE - Write a record to a disk file.
;   Inputs: DE addresses FCB.
;           HL = address to get data.
; Destroys: A,F
;
AMOS_WRITE:	CALL	AMOS_SETDMA
	LD	A,40
	CALL	AMOS_BDOS1
	JR	Z,AMOS_INCSEC
	LD	A,198
	CALL	EXTERR
	DEFM	'Disk full'
	DEFB	0
;
;INCSEC - Increment random record number.
;   Inputs: DE addresses FCB.
; Destroys: F
;
AMOS_INCSEC:	PUSH	HL
	LD	HL,33
	ADD	HL,DE
AMOS_INCS1:	INC	(HL)
	INC	HL
	JR	Z,AMOS_INCS1
	POP	HL
	RET
;
;OPEN - Open a file for access.
;   Inputs: FCB set up.
;  Outputs: DE = FCB
;           A=0 & Z-flag set indicates Not Found.
;           Carry = 0
; Destroys: A,D,E,F
;
AMOS_OPEN:	LD	DE,AMOS_FCB
	LD	A,15
	CALL	AMOS_BDOS1
	INC	A
	RET
;
;CREATE - Create a disk file for writing.
;   Inputs: FCB set up.
;  Outputs: DE = FCB
;           A=0 & Z-flag set indicates directory full.
;           Carry = 0
; Destroys: A,D,E,F
;
AMOS_CREATE:	CALL	AMOS_CHKAMB
	LD	DE,AMOS_FCB
	LD	A,19
	CALL	AMOS_BDOS1			;DELETE
	LD	A,22
	CALL	AMOS_BDOS1			;MAKE
	INC	A
	RET
;
;CHKAMB - Check for ambiguous filename.
; Destroys: A,D,E,F
;
AMOS_CHKAMB:	PUSH	BC
	LD	DE,AMOS_FCB
	LD	B,12
AMOS_CHKAM1:	LD	A,(DE)
	CP	'?'
	JR	Z,AMOS_AMBIG			;AMBIGUOUS
	INC	DE
	DJNZ	AMOS_CHKAM1
	POP	BC
	RET
AMOS_AMBIG:	LD	A,204
	CALL	EXTERR
	DEFM	'Bad name'
	DEFB	0
;
;SETDMA - Set "DMA" address.
;   Inputs: HL = address
; Destroys: A,F
;
AMOS_SETDMA:	LD	A,26
	EX	DE,HL
	CALL	AMOS_BDOS0
	EX	DE,HL
	RET
;
;FIND - Find file parameters from channel.
;   Inputs: E = channel
;  Outputs: DE addresses FCB
;           HL addresses pointer byte (FCB+37)
; Destroys: A,D,E,H,L,F
;
AMOS_FIND:	INC	E
	DEC	E
	JR	Z,AMOS_CHANER
	CALL	AMOS_FIND1
	LD	HL,37
	ADD	HL,DE
	RET	NZ
AMOS_CHANER:	LD	A,222
	CALL	EXTERR
	DEFM	'Invalid channel'
	DEFB	0
;
;FIND1 - Look up file table.
;   Inputs: E = channel
;  Outputs: Z-flag set = file not opened
;           If NZ, DE addresses FCB
;                  HL points into table
; Destroys: A,D,E,H,L,F
;
AMOS_FIND1:	LD	A,E
	AND	7
	ADD	A,A
	LD	E,A
	LD	D,0
	LD	HL,AMOS_TABLE-2
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	A,D
	OR	E
	RET
;
;SETUP - Set up File Control Block.
;   Inputs: HL addresses filename
;           Format  [A:]FILENAME[.EXT]
;           Device defaults to current drive
;           Extension defaults to .BBC
;           A = fill character
;  Outputs: HL updated
;           A = terminator
;           BC = 128
; Destroys: A,B,C,H,L,F
;
;FCB FORMAT (36 BYTES TOTAL):
; 0      0=SAME DISK, 1=DISK A, 2=DISK B (ETC.)
; 1-8    FILENAME, PADDED WITH SPACES
; 9-11   EXTENSION, PADDED WITH SPACES
; 12     CURRENT EXTENT, SET TO ZERO
; 32-35  CLEARED TO ZERO
;
AMOS_SETUP0:	LD	A,' '
AMOS_SETUP:	PUSH	DE
	PUSH	HL
	LD	DE,AMOS_FCB+9
	LD	HL,AMOS_BBC
	LD	BC,3
	LDIR
	LD	HL,AMOS_FCB+32
	LD	B,4
AMOS_SETUP1:	LD	(HL),C
	INC	HL
	DJNZ	AMOS_SETUP1
	POP	HL
	LD	C,A
	XOR	A
	LD	(DE),A
	POP	DE
	CALL	AMOS_SKIPSP
	CP	'"'
	JR	NZ,AMOS_SETUP2
	INC	HL
	CALL	AMOS_SKIPSP
	CALL	AMOS_SETUP2
	CP	'"'
	INC	HL
	JR	Z,AMOS_SKIPSP
AMOS_BADSTR:	LD	A,253
	CALL	EXTERR
	DEFM	'Bad string'
	DEFB	0
;
AMOS_PARSE:	LD	A,(HL)
	INC	HL
	CP	'`'
	RET	NC
	CP	'?'
	RET	C
	XOR	40H
	RET
;
AMOS_SETUP2:	PUSH	DE
	INC	HL
	LD	A,(HL)
	CP	':'
	DEC	HL
	LD	A,B
	JR	NZ,AMOS_DEVICE
	LD	A,(HL)			;DRIVE
	AND	31
	INC	HL
	INC	HL
AMOS_DEVICE:	LD	DE,AMOS_FCB
	LD	(DE),A
	INC	DE
	LD	B,8
AMOS_COPYF:	LD	A,(HL)
	CP	'.'
	JR	Z,AMOS_COPYF1
	CP	' '
	JR	Z,AMOS_COPYF1
	CP	AMOS_CR
	JR	Z,AMOS_COPYF1
	CP	'='
	JR	Z,AMOS_COPYF1
	CP	'"'
	JR	Z,AMOS_COPYF1
	LD	C,'?'
	CP	'*'
	JR	Z,AMOS_COPYF1
	LD	C,' '
	INC	HL
	CP	'|'
	JR	NZ,AMOS_COPYF2
	CALL	AMOS_PARSE
	JR	AMOS_COPYF0
AMOS_COPYF1:	LD	A,C
AMOS_COPYF2:	CALL	AMOS_UPPRC
AMOS_COPYF0:	LD	(DE),A
	INC	DE
	DJNZ	AMOS_COPYF
AMOS_COPYF3:	LD	A,(HL)
	INC	HL
	CP	'*'
	JR	Z,AMOS_COPYF3
	CP	'.'
	LD	BC,3*256+' '
	LD	DE,AMOS_FCB+9
	JR	Z,AMOS_COPYF
	DEC	HL
	POP	DE
	LD	BC,128
AMOS_SKIPSP:	LD	A,(HL)
	CP	' '
	RET	NZ
	INC	HL
	JR	AMOS_SKIPSP
;
AMOS_BBC:	DEFM	'BBC'
;
;HEX - Read a hex string and convert to binary.
;   Inputs: HL = text pointer
;  Outputs: HL = updated text pointer
;           DE = value
;            A = terminator (spaces skipped)
; Destroys: A,D,E,H,L,F
;
AMOS_HEX:	LD	DE,0			;INITIALISE
	CALL	AMOS_SKIPSP
AMOS_HEX1:	LD	A,(HL)
	CALL	AMOS_UPPRC
	CP	'0'
	JR	C,AMOS_SKIPSP
	CP	'9'+1
	JR	C,AMOS_HEX2
	CP	'A'
	JR	C,AMOS_SKIPSP
	CP	'F'+1
	JR	NC,AMOS_SKIPSP
	SUB	7
AMOS_HEX2:	AND	0FH
	EX	DE,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	EX	DE,HL
	OR	E
	LD	E,A
	INC	HL
	JR	AMOS_HEX1
;
;OSCLI - Process an "operating system" command
;
OSCLI:	CALL	AMOS_SKIPSP
	CP	AMOS_CR
	RET	Z
	CP	'|'
	RET	Z
	CP	'.'
	JP	Z,AMOS_DOT			;*.
	EX	DE,HL
	LD	HL,AMOS_COMDS
AMOS_OSCLI0:	LD	A,(DE)
	CALL	AMOS_UPPRC
	CP	(HL)
	JR	Z,AMOS_OSCLI2
	JR	C,AMOS_UNK
AMOS_OSCLI1:	BIT	7,(HL)
	INC	HL
	JR	Z,AMOS_OSCLI1
	INC	HL
	INC	HL
	JR	AMOS_OSCLI0
;
AMOS_OSCLI2:	PUSH	DE
AMOS_OSCLI3:	INC	DE
	INC	HL
	LD	A,(DE)
	CALL	AMOS_UPPRC
	CP	'.'			;ABBREVIATED?
	JR	Z,AMOS_OSCLI4
	XOR	(HL)
	JR	Z,AMOS_OSCLI3
	CP	80H
	JR	Z,AMOS_OSCLI4
	POP	DE
	JR	AMOS_OSCLI1
;
AMOS_OSCLI4:	POP	AF
	INC	DE
AMOS_OSCLI5:	BIT	7,(HL)
	INC	HL
	JR	Z,AMOS_OSCLI5
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	PUSH	HL
	EX	DE,HL
	JP	AMOS_SKIPSP
;
AMOS_UNK:	EX	DE,HL
	JP	AMOS_ASCLI
;
;
BYE:	RST	0			;*BYE, *QUIT
;
AMOS_ERA:	CALL	AMOS_SETUP0			;*ERA, *ERASE
	LD	C,19
	JR	AMOS_XEQ			;"DELETE"
;
AMOS_RES:	LD	C,13			;*RESET
	JR	AMOS_XEQ			;"RESET"
;
AMOS_DRV:	CALL	AMOS_SETUP0			;*DRIVE
	LD	A,(AMOS_FCB)
	DEC	A
	JP	M,AMOS_HUH
	LD	E,A
	LD	C,14
	JR	AMOS_XEQ0
;
AMOS_REN:	CALL	AMOS_SETUP0			;*REN, *RENAME
	CP	'='
	JR	NZ,AMOS_HUH
	INC	HL
	PUSH	HL
	CALL	AMOS_EXISTS
	LD	HL,AMOS_FCB
	LD	DE,AMOS_FCB+16
	LD	BC,12
	LDIR
	POP	HL
	CALL	AMOS_SETUP0
	CALL	AMOS_CHKAMB
	LD	C,23
AMOS_XEQ:	LD	DE,AMOS_FCB
AMOS_XEQ0:	LD	A,(HL)
	CP	AMOS_CR
	JR	NZ,AMOS_HUH
AMOS_BDC:	LD	A,C
	CALL	AMOS_BDOS1
	RET	P
AMOS_HUH:	LD	A,254
	CALL	EXTERR
	DEFM	'Bad command'
	DEFB	0
;
AMOS_EXISTS:	LD	HL,AMOS_DSKBUF
	CALL	AMOS_SETDMA
	LD	DE,AMOS_FCB
	LD	A,17
	CALL	AMOS_BDOS1			;SEARCH
	INC	A
	RET	Z
	LD	A,196
	CALL	EXTERR
	DEFM	'File exists'
	DEFB	0
;
AMOS_SAVLOD:	CALL	AMOS_SETUP0			;PART OF *SAVE, *LOAD
	CALL	AMOS_HEX
	CP	'+'
	PUSH	AF
	PUSH	DE
	JR	NZ,AMOS_SAVLO1
	INC	HL
AMOS_SAVLO1:	CALL	AMOS_HEX
	CP	AMOS_CR
	JR	NZ,AMOS_HUH
	EX	DE,HL
	POP	DE
	POP	AF
	RET	Z
	OR	A
	SBC	HL,DE
	RET	NZ
	JR	AMOS_HUH
;
AMOS_DOT:	INC	HL
AMOS_DIR:	LD	A,'?'			;*DIR
	CALL	AMOS_SETUP
	CP	AMOS_CR
	JR	NZ,AMOS_HUH
	LD	C,17
AMOS_DIR0:	LD	B,4
AMOS_DIR1:	CALL	LTRAP
	LD	DE,AMOS_FCB
	LD	HL,AMOS_DSKBUF
	CALL	AMOS_SETDMA
	LD	A,C
	CALL	AMOS_BDOS1			;SEARCH DIRECTORY
	JP	M,CRLF
	RRCA
	RRCA
	RRCA
	AND	60H
	LD	E,A
	LD	D,0
	LD	HL,AMOS_DSKBUF+1
	ADD	HL,DE
	PUSH	HL
	LD	DE,8
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	BIT	7,(HL)			;SYSTEM FILE?
	POP	HL
	LD	C,18
	JR	NZ,AMOS_DIR1
	PUSH	BC
	LD	A,B
	CP	4
	LD	A,' '
	CALL	Z,AMOS_DRIVE
	CALL	OSWRCH
	LD	B,8
	LD	A,' '
	BIT	7,E			;READ ONLY?
	JR	Z,AMOS_DIR3
	LD	A,'*'
AMOS_DIR3:	CALL	AMOS_CPTEXT
	LD	B,3
	LD	A,' '
	CALL	AMOS_SPTEXT
	POP	BC
	DJNZ	AMOS_DIR1
	CALL	CRLF
	JR	AMOS_DIR0
;
AMOS_DRIVE:	LD	A,(AMOS_FCB)
	DEC	A
	LD	C,25
	CALL	M,AMOS_BDC
	ADD	A,'A'
	RET
;
AMOS_UPPRC:	AND	7FH
	CP	'`'
	RET	C
	AND	5FH			;CONVERT TO UPPER CASE
	RET
;
AMOS_HELP:	LD	B,32			;*HELP
	LD	HL,VERMSG
	JP	AMOS_PTEXT
;
;
AMOS_COMDS:	DEFM	'BY'
	DEFB	'E'+80H
	DEFW	BYE
	DEFM	'CP'
	DEFB	'M'+80H
	DEFW	BYE
	DEFM	'DI'
	DEFB	'R'+80H
	DEFW	AMOS_DIR
	DEFM	'DRIV'
	DEFB	'E'+80H
	DEFW	AMOS_DRV
	DEFM	'ERAS'
	DEFB	'E'+80H
	DEFW	AMOS_ERA
	DEFM	'ER'
	DEFB	'A'+80H
	DEFW	AMOS_ERA
	DEFM	'HEL'
	DEFB	'P'+80H
	DEFW	AMOS_HELP
	DEFM	'LOA'
	DEFB	'D'+80H
	DEFW	AMOS_STLOAD
	DEFM	'QUI'
	DEFB	'T'+80H
	DEFW	BYE
	DEFM	'RENAM'
	DEFB	'E'+80H
	DEFW	AMOS_REN
	DEFM	'RE'
	DEFB	'N'+80H
	DEFW	AMOS_REN
	DEFM	'RESE'
	DEFB	'T'+80H
	DEFW	AMOS_RES
	DEFM	'SAV'
	DEFB	'E'+80H
	DEFW	AMOS_STSAVE
	DEFM	'TYP'
	DEFB	'E'+80H
	DEFW	AMOS_TYPE
	DEFB	0FFH
;
;PROCESS 6502's BRK INSTRUCTION
;
AMOS_BRK:	LD	HL,(AMOS_BRKPTR)
	PUSH	HL
AMOS_BRKTRP:	POP	HL
	LD	A,(HL)
	INC	HL
	PUSH	HL
	JP	EXTERR
;
;TRAP - Test for "ESC" and abort if so.
;  Destroys: A,H,L,F
;
TRAP:
LTRAP:	LD	A,(AMOS_BRKFLG)
	OR	A
	RET	P
AMOS_ESC:	LD	A,126
	CALL	AMOS_ASBYTE
	JP	ESCAPE
;
;PTEXT - Print text
;   Inputs: HL = address of text
;            B = number of characters to print
; Destroys: A,B,H,L,F
;
AMOS_CPTEXT:	PUSH	AF
	LD	A,':'
	CALL	OSWRCH
	POP	AF
AMOS_SPTEXT:	CALL	OSWRCH
AMOS_PTEXT:	LD	A,(HL)
	AND	7FH
	INC	HL
	CALL	OSWRCH
	DJNZ	AMOS_PTEXT
	RET
;
;OSINIT - Initialise RAM mapping etc.
;If BASIC is entered by BBCBASIC FILENAME then file
;FILENAME.BBC is automatically CHAINed.
;   Outputs: DE = initial value of HIMEM (top of RAM)
;            HL = initial value of PAGE (user program)
;            Z-flag reset indicates AUTO-RUN.
;  Destroys: A,B,C,D,E,H,L,F
;
OSINIT:	LD	A,0C3H
	LD	(38H),A
	LD	HL,AMOS_BRKTRP
	LD	(39H),HL
	LD	HL,AMOS_BRK
	LD	(AMOS_BRKVEC),HL
	LD	A,229
	LD	HL,0
	CALL	AMOS_ASBYTE			;ESC interrupts program
	LD	A,230
	LD	HL,0
	CALL	AMOS_ASBYTE			;ESC flushes buffers
	LD	C,45
	LD	E,254
	CALL	AMOS_BDOS			;TRAP ERRORS (CP/M 3)
	XOR	A
	LD	B,AMOS_INILEN
	LD	HL,AMOS_TABLE
AMOS_CLRTAB:	LD	(HL),A			;CLEAR FILE TABLE
	INC	HL
	DJNZ	AMOS_CLRTAB
	LD	DE,ACCS
	LD	HL,AMOS_DSKBUF
	LD	C,(HL)
	INC	HL
	CP	C
	JR	Z,AMOS_NOBOOT
	LDIR	;COPY TO ACCS
AMOS_NOBOOT:	EX	DE,HL
	LD	(HL),AMOS_CR
	LD	DE,(6)			;DE = HIMEM
	LD	E,A			;PAGE BOUNDARY
	LD	HL,USER
	RET
;
;OSRDCH - Read a character from console input.
;  Outputs: A = character.
; Destroys: A,F
;
OSRDCH:	PUSH	BC
	PUSH	DE
	PUSH	HL
	CALL	AMOS_ASRDCH
	POP	HL
	POP	DE
	POP	BC
	RET
;
;OSWRCH - Write a character to console output.
;   Inputs: A = character.
; Destroys: Nothing
;
PROMPT:	LD	A,'>'
OSWRCH:	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	CALL	AMOS_ASWRCH
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET
;
;OSLINE - Read a complete line, terminated by 
;carriage-return.
;   Inputs: HL addresses destination buffer.
;           (L=0)
;  Outputs: Buffer filled, terminated by CR.
;           A=0.
;  Destroys: A,B,C,D,E,H,L,IX,F
;
OSLINE:	LD	IX,SCRAP
	LD	(IX+0),L
	LD	(IX+1),H
	LD	(IX+2),255		;MAX. LINE LENGTH
	LD	(IX+3),' '		;MIN. ASCII VALUE
	LD	(IX+4),255		;MAX. ASCII VALUE
	LD	A,218
	LD	HL,0
	CALL	AMOS_ASBYTE			;FLUSH VDU QUEUE
	XOR	A
	LD	HL,SCRAP
	CALL	AMOS_ASWORD
	JP	C,AMOS_ESC
	XOR	A
	RET
;
AMOS_CR:	EQU	0DH
AMOS_FCBSIZ:	EQU	128+36+2
;
AMOS_BDOS:	EQU	5
;
AMOS_BRKFLG:	EQU	0FF80H
AMOS_BRKPTR:	EQU	0FF82H
AMOS_ASRDCH:	EQU	0FFE0H
AMOS_ASWRCH:	EQU	0FFEEH
AMOS_ASWORD:	EQU	0FFF1H
AMOS_ASBYTE:	EQU	0FFF4H
AMOS_ASCLI:	EQU	0FFF7H
AMOS_BRKVEC:	EQU	0FFFAH
;
AMOS_FCB:	EQU	5CH
AMOS_DSKBUF:	EQU	80H
;
AMOS_TABLE:	DEFS	14			;FILE BLOCK POINTERS
AMOS_INILEN:	EQU	$-AMOS_TABLE
SCRAP:	DEFS	31
	DEFB	0
;
AMOS_FIN:
                                                                                                       
