; generated from src/EVAL.Z80 by pasmo/m80topasmo.py -- do not edit
;
;BBC BASIC INTERPRETER - Z80 VERSION
;EVALUATE EXPRESSION MODULE - "EVAL"
;(C) COPYRIGHT R.T.RUSSELL 1981-2025
;
;THE NAME BBC BASIC IS USED WITH THE PERMISSION
;OF THE BRITISH BROADCASTING CORPORATION AND IS
;NOT TRANSFERRABLE TO A FORKED OR DERIVED WORK.
;
;VERSION 2.3, 07-05-1984
;VERSION 3.0, 08-03-1987
;VERSION 5.0, 31-05-2024
;VERSION 5.1, 28-12-2024
;VERSION 5.2, 11-01-2025
;VERSION 5.3, 16-03-2025 (Shifts moved to new codes)
;
;BINARY FLOATING POINT REPRESENTATION:
; 32 BIT SIGN-MAGNITUDE NORMALIZED MANTISSA
; 8 BIT EXCESS-128 SIGNED EXPONENT
; SIGN BIT REPLACES MANTISSA MSB (IMPLIED "1")
; MANTISSA=0 & EXPONENT=0 IMPLIES VALUE IS ZERO.
;
;BINARY INTEGER REPRESENTATION:
; 32 BIT 2'S-COMPLEMENT SIGNED INTEGER
; "EXPONENT" BYTE = 0 (WHEN PRESENT)
;
;NORMAL REGISTER ALLOCATION: MANTISSA - HLH'L'
;                            EXPONENT - C
;
;
;
;
;
;
;
;
EVAL_FUNTOK:	EQU	8DH			;1st FUNCTION TOKEN
EVAL_TMOD:	EQU	83H
EVAL_TLEN:	EQU	0A9H
EVAL_TTO:	EQU	0B8H
EVAL_TDIM:	EQU	0DEH
EVAL_TEND:	EQU	0E0H
EVAL_TMODE:	EQU	0EBH
EVAL_TREPORT:	EQU	0F6H
EVAL_TWIDTH:	EQU	0FEH
EVAL_TTINT:	EQU	0AH
EVAL_TBY:	EQU	0FH
;
;TABLE OF ADDRESSES FOR FUNCTIONS:
;
EVAL_FUNTBL:	DEFW	DECODE			;Line number
	DEFW	EVAL_OPENIN			;OPENIN
	DEFW	EVAL_PTR			;PTR
	DEFW	EVAL_PAGEV			;PAGE
	DEFW	EVAL_TIMEV			;TIME
	DEFW	EVAL_LOMEMV			;LOMEM
	DEFW	EVAL_HIMEMV			;HIMEM
	DEFW	EVAL_ABS			;ABS
	DEFW	EVAL_ACS			;ACS
	DEFW	ADVAL			;ADVAL
	DEFW	EVAL_ASC			;ASC
	DEFW	EVAL_ASN			;ASN
	DEFW	EVAL_ATN			;ATN
	DEFW	EVAL_BGET			;BGET
	DEFW	EVAL_COS			;COS
	DEFW	EVAL_COUNTV			;COUNT
	DEFW	EVAL_DEG			;DEG
	DEFW	EVAL_ERLV			;ERL
	DEFW	EVAL_ERRV			;ERR
	DEFW	EVAL_EVAL			;EVAL
	DEFW	EVAL_EXP			;EXP
	DEFW	EVAL_EXT			;EXT
	DEFW	ZERO			;FALSE
	DEFW	FN			;FN
	DEFW	EVAL_GET			;GET
	DEFW	EVAL_INKEY			;INKEY
	DEFW	EVAL_INSTR			;INSTR(
	DEFW	EVAL_INT			;INT
	DEFW	EVAL_LEN			;LEN
	DEFW	EVAL_LN			;LN
	DEFW	EVAL_LOG			;LOG
	DEFW	EVAL_CPL			;NOT
	DEFW	EVAL_OPENUP			;OPENUP
	DEFW	EVAL_OPENOT			;OPENOUT
	DEFW	EVAL_PI			;PI
	DEFW	POINT			;POINT(
	DEFW	EVAL_POS			;POS
	DEFW	EVAL_RAD			;RAD
	DEFW	EVAL_RND			;RND
	DEFW	EVAL_SGN			;SGN
	DEFW	EVAL_SIN			;SIN
	DEFW	EVAL_SQR			;SQR
	DEFW	EVAL_TAN			;TAN
	DEFW	EVAL_TOPV			;TO(P)
	DEFW	EVAL_TRUE			;TRUE
	DEFW	USR			;USR
	DEFW	EVAL_VAL			;VAL
	DEFW	EVAL_VPOS			;VPOS
	DEFW	EVAL_CHRS			;CHR$
	DEFW	EVAL_GETS			;GET$
	DEFW	EVAL_INKEYS			;INKEY$
	DEFW	EVAL_LEFTS			;LEFT$(
	DEFW	EVAL_MIDS			;MID$(
	DEFW	EVAL_RIGHTS			;RIGHT$(
	DEFW	EVAL_STRS			;STR$
	DEFW	EVAL_STRING			;STRING$(
	DEFW	EVAL_EOF			;EOF
	DEFW	EVAL_SUM			;SUM
;
EVAL_TCMD:	EQU	EVAL_FUNTOK+($-EVAL_FUNTBL)/2
;
EVAL_CR:	EQU	0DH
EVAL_LF:	EQU	0AH
EVAL_AND:	EQU	80H
EVAL_DIV:	EQU	81H
EVAL_EOR:	EQU	82H
EVAL_MOD:	EQU	83H
EVAL_OR:	EQU	84H
;
EVAL_SOPTBL:	DEFW	EVAL_SLE			;<= (STRING)
	DEFW	EVAL_SNE			;<>
	DEFW	EVAL_SGE			;>=
	DEFW	EVAL_SLT			;<
	DEFW	EVAL_SEQ			;=
	DEFW	EVAL_SGT			;>
;
;EXPR - VARIABLE-TYPE EXPRESSION EVALUATION
; Expression type is returned in A'F':
; Numeric - A' bit 7=0, F' sign bit cleared.
; String - A' bit 7=1, F' sign bit set.
;Floating-point or integer result returned in HLH'L'C
; Integer result denoted by C=0 and HLH'L' non-zero.
;String result returned in string accumulator, DE set.
;
;Hierarchy is: (1) Variables, functions,
; constants, bracketed expressions.
; (2) ^
; (3) * / MOD DIV
; (4) + -
; (5) = <> <= >= > <
; (6) AND
; (7) EOR OR
;
EXPR:	CALL	EVAL_EXPR1			;GET FIRST OPERAND
EVAL_EXPR0A:	CP	EVAL_EOR			;CHECK OPERATOR
	JR	Z,EVAL_EXPR0B
	CP	EVAL_OR
	RET	NZ
EVAL_EXPR0B:	CALL	EVAL_SAVE			;SAVE FIRST OPERAND
	CALL	EVAL_EXPR1			;GET SECOND OPERAND
	CALL	EVAL_DOIT			;DO OPERATION
	JR	EVAL_EXPR0A			;CONTINUE
;
EVAL_EXPR1:	CALL	EVAL_EXPR2
EVAL_EXPR1A:	CP	EVAL_AND
	RET	NZ
	CALL	EVAL_SAVE
	CALL	EVAL_EXPR2
	CALL	EVAL_DOIT
	JR	EVAL_EXPR1A
;
EVAL_EXPR2:	CALL	EVAL_EXPR3
	CALL	EVAL_RELOPQ
	RET	NZ
	LD	B,A
	INC	IY			;BUMP OVER OPERATOR
	CALL	NXT
	CALL	EVAL_RELOPQ			;COMPOUND OPERATOR?
	JR	NZ,EVAL_EXPR2B
	INC	IY
	CP	B
	JR	Z,EVAL_SHIFT			;SHIFT OR ==
	ADD	A,B
	LD	B,A
EVAL_EXPR2B:	LD	A,B
	EX	AF,AF'
	JP	M,EVAL_EXPR2S
	EX	AF,AF'
	SUB	4
	CP	'>'-4
	JR	NZ,EVAL_EXPR2C
	ADD	A,2
EVAL_EXPR2C:	AND	0FH
EVAL_EXPR2D:	CALL	EVAL_SAVE1
	CALL	EVAL_EXPR3
	CALL	EVAL_DOIT			;Must NOT be "JP DOIT"
	RET
;
EVAL_SHIFT:	CP	'='
	JR	Z,EVAL_EXPR2B		;==
	CALL	NXT
	CALL	EVAL_RELOPQ
	JR	NZ,EVAL_SHIFT1
	CP	B
	JP	NZ,SYNTAX
	INC	IY
	INC	B
EVAL_SHIFT1:	LD	A,B
	SUB	16
	JR	EVAL_EXPR2D
;
EVAL_EXPR2S:	EX	AF,AF'
	DEC	A
	AND	7
	CALL	PUSHS			;SAVE STRING ON STACK
	PUSH	AF			;SAVE OPERATOR
	CALL	EVAL_EXPR3			;SECOND STRING
	EX	AF,AF'
	JP	P,EVAL_MISMAT
	POP	AF
	LD	C,E			;LENGTH OF STRING #2
	POP	DE
	LD	HL,0
	ADD	HL,SP
	LD	B,E			;LENGTH OF STRING #1
	PUSH	DE
	LD	DE,ACCS
	EX	DE,HL
	CALL	EVAL_DISPT2
	POP	DE
	EX	DE,HL
	LD	H,0
	ADD	HL,SP
	LD	SP,HL
	EX	DE,HL
	XOR	A			;NUMERIC MARKER
	LD	C,A			;INTEGER MARKER
	EX	AF,AF'
	LD	A,(IY)
	RET
;
EVAL_EXPR3:	CALL	EVAL_EXPR4
EVAL_EXPR3A:	CP	'-'
	JR	Z,EVAL_EXPR3B
	CP	'+'
	RET	NZ
	EX	AF,AF'
	JP	M,EVAL_EXPR3S
	EX	AF,AF'
EVAL_EXPR3B:	CALL	EVAL_SAVE
	CALL	EVAL_EXPR4
	CALL	EVAL_DOIT
	JR	EVAL_EXPR3A
;
EVAL_EXPR3S:	EX	AF,AF'
	INC	IY			;BUMP PAST '+'
	CALL	PUSHS			;SAVE STRING ON STACK
	CALL	EVAL_EXPR4			;SECOND STRING
	EX	AF,AF'
	JP	P,EVAL_MISMAT
	LD	C,E			;C=LENGTH
	POP	DE
	PUSH	DE
	LD	HL,ACCS
	LD	D,H
	LD	A,C
	OR	A
	JR	Z,EVAL_EXP3S3
	LD	B,L
	LD	L,A			;SOURCE
	ADD	A,E
	LD	E,A			;DESTINATION
	LD	A,19
	JR	C,EVAL_ERROR2		;"String too long"
	PUSH	DE
	DEC	E
	DEC	L
	LDDR	;COPY
	POP	DE
EVAL_EXP3S3:	EXX
	POP	BC
	CALL	POPS			;RESTORE FROM STACK
	EXX
	OR	80H			;FLAG STRING
	EX	AF,AF'
	LD	A,(IY)
	JR	EVAL_EXPR3A
;
EVAL_EXPR4:	CALL	EVAL_EXPR5
EVAL_EXPR4A:	CP	'*'
	JR	Z,EVAL_EXPR4B
	CP	'/'
	JR	Z,EVAL_EXPR4B
	CP	EVAL_MOD
	JR	Z,EVAL_EXPR4B
	CP	EVAL_DIV
	RET	NZ
EVAL_EXPR4B:	CALL	EVAL_SAVE
	CALL	EVAL_EXPR5
	CALL	EVAL_DOIT
	JR	EVAL_EXPR4A
;
EVAL_EXPR45:	LD	A,E
	CP	'+'
	JR	Z,EVAL_EXPR4
	CP	'-'
	JR	Z,EVAL_EXPR4
EVAL_EXPR5:	CALL	EVAL_ITEM
	OR	A			;TEST TYPE
	EX	AF,AF'			;SAVE TYPE
EVAL_EXPR5A:	CALL	NXT
	CP	'^'
	RET	NZ
	CALL	EVAL_SAVE
	CALL	EVAL_ITEM
	OR	A
	EX	AF,AF'
	CALL	EVAL_DOIT
	JR	EVAL_EXPR5A
;
EXPRN:	CALL	EXPR
	EX	AF,AF'
	RET	P
	JR	EVAL_MISMAT
;
EXPRI:	CALL	EXPR
	EX	AF,AF'
	JP	P,SFIX
	JR	EVAL_MISMAT
;
EXPRS:	CALL	EXPR
	EX	AF,AF'
	RET	M
	JR	EVAL_MISMAT
;
EVAL_BADHEX:	LD	A,28
EVAL_ERROR2:	JP	ERROR			;"Bad HEX or binary"
;
EVAL_NEGATE:	EXX
	LD	A,H
	CPL
	LD	H,A
	LD	A,L
	CPL
	LD	L,A
	EXX
	LD	A,H
	CPL
	LD	H,A
	LD	A,L
	CPL
	LD	L,A
EVAL_ADD1:	EXX
	INC	HL
	LD	A,H
	OR	L
	EXX
	LD	A,0			;NUMERIC MARKER
	RET	NZ
	INC	HL
	RET
;
ITEMI:	CALL	EVAL_ITEM
	OR	A
	JP	P,SFIX
	JR	EVAL_MISMAT
;
EVAL_ITEMS:	CALL	EVAL_ITEM
	OR	A
	RET	M
EVAL_MISMAT:	LD	A,6
	JR	EVAL_ERROR2			;"Type mismatch"
;
EVAL_ITEM1:	CALL	EXPR			;BRACKETED EXPR
	CALL	BRAKET
	EX	AF,AF'
	RET
;
EVAL_ITEMN:	CALL	EVAL_ITEM
	OR	A
	RET	P
	JR	EVAL_MISMAT
;
;HEX - Get hexadecimal constant.
;   Inputs: ASCII string at (IY)
;  Outputs: Integer result in H'L'HL, C=0, A7=0.
;           IY updated (points to delimiter)
;
EVAL_HEX:	CALL	ZERO
	CALL	EVAL_HEXDIG
	JR	C,EVAL_BADHEX
EVAL_HEX1:	INC	IY
	AND	0FH
	LD	B,4
EVAL_HEX2:	EXX
	ADD	HL,HL
	EXX
	ADC	HL,HL
	DJNZ	EVAL_HEX2
	EXX
	OR	L
	LD	L,A
	EXX
	CALL	EVAL_HEXDIG
	JR	NC,EVAL_HEX1
	XOR	A
	RET
;
;BIN - Get binary constant.
;   Inputs: ASCII string at (IY)
;  Outputs: Integer result in H'L'HL, C=0, A=0.
;           IY updated (points to delimiter)
;
EVAL_BIN:	CALL	ZERO
	CALL	EVAL_BINDIG
	JR	C,EVAL_BADHEX
EVAL_BIN1:	INC	IY
	RR	A
	EXX
	ADC	HL,HL
	EXX
	ADC	HL,HL
	CALL	EVAL_BINDIG
	JR	NC,EVAL_BIN1
	XOR	A
	RET
;
;MINUS - Unary minus.
;   Inputs: IY = text pointer
;  Outputs: Numeric result, same type as argument.
;           Result in H'L'HLC
;
EVAL_MINUS:	CALL	EVAL_ITEMN
EVAL_MINUS0:	DEC	C
	INC	C
	JR	Z,EVAL_NEGATE		;ZERO/INTEGER
	LD	A,H
	XOR	80H			;CHANGE SIGN (FP)
	LD	H,A
	XOR	A			;NUMERIC MARKER
	RET
;
EVAL_ADDROF:	CALL	VAR
	PUSH	HL
	EXX
	POP	HL
	JP	EVAL_COUNT1
;
;ITEM - VARIABLE TYPE NUMERIC OR STRING ITEM.
;Item type is returned in A: Bit 7=0 numeric.
; Bit 7=1 string.
;Numeric item returned in HLH'L'C.
;String item returned in string accumulator,
; DE addresses byte after last (E=length).
;
EVAL_ITEM:	CALL	CHECK
	CALL	NXT
	INC	IY
	CP	EVAL_FUNTOK
	JR	C,EVAL_ITEM0
	CP	EVAL_TCMD
	JP	C,EVAL_DISPAT		;FUNCTIONS
	JP	EVAL_EXTRAS			;DIM, END, MODE, REPORT$, WIDTH
;
EVAL_ITEM0:	CP	':'
	JR	NC,EVAL_ITEM2		;VARIABLES 
	CP	'0'
	JR	NC,EVAL_CON			;NUMERIC CONSTANT
	CP	'('
	JR	Z,EVAL_ITEM1			;EXPRESSION
	CP	'-'
	JR	Z,EVAL_MINUS			;UNARY MINUS
	CP	'+'
	JR	Z,EVAL_ITEMN			;UNARY PLUS
	CP	'.'
	JR	Z,EVAL_CON			;NUMERIC CONSTANT
	CP	'&'
	JR	Z,EVAL_HEX			;HEX CONSTANT
	CP	'%'
	JR	Z,EVAL_BIN			;BINARY CONSTANT
	CP	'"'
	JR	Z,CONS			;STRING CONSTANT
	CP	EVAL_TTINT
	JP	Z,EVAL_TINT			;TINT FUNCTION
EVAL_ITEM2:	CP	EVAL_TMOD	
	JP	Z,EVAL_MODFUN		;MOD
	CP	'^'
	JR	Z,EVAL_ADDROF		;^ OPERATOR
	DEC	IY
	CALL	GETVAR			;VARIABLE
	JR	NZ,EVAL_NOSUCH
	BIT	6,A
	JR	NZ,EVAL_ARRAY
	OR	A
	JP	M,LOADS			;STRING VARIABLE
LOADN:	BIT	2,A
	LD	C,0
	JR	Z,EVAL_LOAD1			;BYTE VARIABLE
	BIT	0,A
	JR	Z,LOAD4			;INTEGER VARIABLE
EVAL_LOAD5:	LD	C,(IX+4)
LOAD4:	EXX
	LD	L,(IX+0)
	LD	H,(IX+1)
	EXX
	LD	L,(IX+2)
	LD	H,(IX+3)
	RET
;
EVAL_LOAD1:	LD	HL,0
	EXX
	LD	H,0
	LD	L,(IX+0)
	EXX
	RET
;
EVAL_NOSUCH:	JP	C,SYNTAX
	LD	A,(LISTON)
	BIT	5,A
	LD	A,26
	JR	NZ,EVAL_ERROR0		;"No such variable"
EVAL_NOS1:	INC	IY
	CALL	RANGE
	JR	NC,EVAL_NOS1
	LD	IX,PC
	XOR	A
	LD	C,A
	JR	LOAD4
;
;CON - Get unsigned numeric constant from ASCII string.
;   Inputs: ASCII string at (IY-1)
;  Outputs: Variable-type result in HLH'L'C
;           IY updated (points to delimiter)
;           A7 = 0 (numeric marker)
;
EVAL_CON:	DEC	IY
	PUSH	IY
	POP	IX
	LD	A,36
	CALL	FPP
	JR	C,EVAL_ERROR0
	PUSH	IX
	POP	IY
	XOR	A
	RET
;
;CONS - Get string constant from ASCII string.
;   Inputs: ASCII string at (IY)
;  Outputs: Result in string accumulator.
;           D = MS byte of ACCS, E = string length
;           A7 = 1 (string marker)
;           IY updated
;
CONS:	LD	DE,ACCS
EVAL_CONS3:	LD	A,(IY)
	INC	IY
	CP	'"'
	JR	Z,EVAL_CONS2
EVAL_CONS1:	LD	(DE),A
	INC	E
	CP	EVAL_CR
	JR	NZ,EVAL_CONS3
	LD	A,9
EVAL_ERROR0:	JP	ERROR			;"Missing """
;
EVAL_CONS2:	LD	A,(IY)
	CP	'"'
	INC	IY
	JR	Z,EVAL_CONS1
	DEC	IY
	LD	A,80H			;STRING MARKER
	RET
;
EVAL_ARRAY:	LD	A,14			;'Bad use of array'
	JR	EVAL_ERROR0
;
; ARRLEN - Get start address and number of elements of an array
;   Inputs: HL addresses array descriptor
;  Outputs: HL = address of first element
;           DE = total number of elements
;           A = 0
; Destroys: A,B,C,D,E,H,L,flags
;
EVAL_ARRLEN:	LD	A,(HL)			;Number of dimensions
	INC	HL
	OR	A
	JR	Z,EVAL_ARRAY
	LD	DE,1
EVAL_ARLOOP:	LD	C,(HL)
	INC	HL
	LD	B,(HL)			;BC = size of this dimension
	INC	HL
	EX	DE,HL
	PUSH	AF
	PUSH	DE
	CALL	MUL16			;HL=HL*BC
	POP	DE
	POP	AF
	EX	DE,HL
	DEC	A
	JR	NZ,EVAL_ARLOOP
	RET
;
EVAL_GETARR:	CALL	NXT
	CALL	GETVAR
	JR	NZ,EVAL_NOSUCH
	BIT	6,A
	SCF
	JR	Z,EVAL_NOSUCH
	AND	8FH
	LD	B,A			;Type + size
EVAL_GETAR1:	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	AND	0FEH
	OR	H
	JR	Z,EVAL_ARRAY			;Bad use of array
	RET
;
EVAL_GETARB:	CALL	NXT
	CP	'('
	JR	NZ,EVAL_GETARR
	INC	IY
	CALL	EVAL_GETARR
	CALL	BRAKET
	RET
;
EVAL_DLOADN:	BIT	2,A
	LD	B,0
	JR	Z,EVAL_DLOAD1		;BYTE VARIABLE
	BIT	0,A
	JR	Z,EVAL_DLOAD4		;INTEGER VARIABLE
DLOAD5:	LD	B,(IX+4)
EVAL_DLOAD4:	EXX
	LD	E,(IX+0)
	LD	D,(IX+1)
	EXX
	LD	E,(IX+2)
	LD	D,(IX+3)
	RET
;
EVAL_DLOAD1:	LD	DE,0
	EXX
	LD	D,0
	LD	E,(IX+0)
	EXX
	RET
;
LOADS:	LD	DE,ACCS
	RRA
	JR	NC,EVAL_LOADS2		;FIXED STRING
	CALL	LOAD4
	EXX
	LD	A,L
	EXX
	OR	A
	LD	C,A
EVAL_REPDUN:	LD	A,80H			;STRING MARKER
	RET	Z
	LD	B,0
	LDIR
	RET
;
EVAL_LOADS2:	PUSH	IX
	POP	HL
EVAL_LOADS3:	LD	A,(HL)
	LD	(DE),A
	INC	HL
	CP	EVAL_CR
	JR	Z,EVAL_REPDUN
	INC	E
	JR	NZ,EVAL_LOADS3
	RET	;RETURN NULL STRING
;
; Version 5 extensions:
;
EVAL_EXTRAS:	CP	EVAL_TMODE
	JP	Z,MODEFN		;MODE
	CP	EVAL_TWIDTH
	JP	Z,WIDFN			;WIDTH
	CP	EVAL_TREPORT
	JR	Z,EVAL_REPORS		;REPORT$
	CP	EVAL_TEND
	JR	Z,EVAL_ENDFUN		;END
	CP	EVAL_TDIM
	JR	Z,EVAL_DIMFUN		;DIM
EVAL_SYNERR:	JP	SYNTAX			; 'Syntax error'
;
; END (function)
;
EVAL_ENDFUN:	LD	HL,(FREE)
	JP	EVAL_COUNT1
;
; REPORT$
;
EVAL_REPORS:	LD	A,(IY)
	CP	'$'
	JR	NZ,EVAL_SYNERR
	INC	IY
	LD	HL,(ERRTXT)
	LD	DE,ACCS
EVAL_REPCPY:	LD	A,(HL)
	OR	A
	JR	Z,EVAL_REPDUN
	LDI
	CP	160
	JP	PE,EVAL_REPCPY
	CP	EVAL_LF
	JR	Z,EVAL_REPCPY
	DEC	E
	PUSH	HL
	LD	HL,KEYWDS
	LD	BC,KEYWDL
	CPIR
	LD	B,160
	CP	145
	JP	PE,EVAL_REPTOK
	INC	B
EVAL_REPTOK:	LD	A,(HL)
	LDI
	CP	B
	JP	PE,EVAL_REPTOK
	POP	HL
	DEC	E
	JR	EVAL_REPCPY
;
; DIM(array()[,sub])
;
EVAL_DIMFUN:	CALL	NXT
	CP	'('
	JR	NZ,EVAL_DIMF0
	INC	IY
	CALL	EVAL_DIMF0
	CALL	BRAKET
	RET
;
EVAL_DIMF0:	CALL	EVAL_GETARR
	PUSH	HL
	CALL	NXT
	LD	E,0
	CP	','
	JR	NZ,EVAL_DIMF1
	INC	IY
	CALL	EXPRI
	EXX
	EX	DE,HL
	INC	E
	DEC	E
	JR	Z,EVAL_BADSUB
EVAL_DIMF1:	POP	HL
	LD	A,(HL)
	INC	HL
	CP	E
	JR	C,EVAL_BADSUB
	DEC	E
	JP	M,EVAL_DIMF3
	ADD	HL,DE
	ADD	HL,DE
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	DEC	HL
EVAL_DIMF2:	JP	EVAL_COUNT1

EVAL_DIMF3:	LD	L,A
	LD	H,0
	JR	EVAL_DIMF2
;
EVAL_BADSUB:	LD	A,15
	JP	ERROR				;"Bad subscript"
;
;VARIABLE-TYPE FUNCTIONS:
;
;Result returned in HLH'L'C (floating point)
;Result returned in HLH'L' (C=0) (integer)
;Result returned in string accumulator & DE (string)
;All registers destroyed.
;IY (text pointer) updated.
;Bit 7 of A indicates type: 0 = numeric, 1 = string.
;
;
;POS - horizontal cursor position.
;VPOS - vertical cursor position.
;EOF - return status of file.
;BGET - read byte from file.
;INKEY - as GET but wait only n centiseconds.
;GET - wait for keypress and return ASCII value.
;GET(n) - input from Z80 port n.
;ASC - ASCII value of string.
;LEN - length of string.
;LOMEM - location of dynamic variables.
;HIMEM - top of available RAM.
;PAGE - start of current text page.
;TOP - address of first free byte after program.
;ERL - line number where last error occurred.
;ERR - number of last error.
;COUNT - number of printing characters since CR.
;Results are integer numeric.
;
EVAL_TINT:	CALL	TINTFN
	JR	EVAL_COUNT1
EVAL_POS:	CALL	GETCSR
	EX	DE,HL
	JR	EVAL_COUNT1
EVAL_VPOS:	CALL	GETCSR
	JR	EVAL_COUNT1
EVAL_EOF:	CALL	CHANEL
	CALL	OSSTAT
	JP	Z,EVAL_TRUE
	JP	ZERO
EVAL_BGET:	CALL	CHANEL			;CHANNEL NUMBER
	CALL	OSBGET
	LD	L,A
	JR	EVAL_COUNT0
EVAL_INKEY:	CALL	EVAL_INKEYS
	JR	EVAL_ASC0
EVAL_GET:	CALL	NXT
	CP	'('
	JR	NZ,EVAL_GET0
	CALL	ITEMI			;PORT ADDRESS
	EXX
	LD	B,H
	LD	C,L
	IN	L,(C)			;INPUT FROM PORT BC
	JR	EVAL_COUNT0
EVAL_GET0:	CALL	EVAL_GETS
	JR	EVAL_ASC1
EVAL_ASC:	CALL	EVAL_ITEMS
EVAL_ASC0:	XOR	A
	CP	E
	JP	Z,EVAL_TRUE			;NULL STRING
EVAL_ASC1:	LD	HL,(ACCS)
	JR	EVAL_COUNT0
EVAL_LEN:	CALL	EVAL_ITEMS
	EX	DE,HL
	JR	EVAL_COUNT0
EVAL_LOMEMV:	LD	HL,(LOMEM)
	JR	EVAL_COUNT1
EVAL_HIMEMV:	LD	HL,(HIMEM)
	JR	EVAL_COUNT1
EVAL_PAGEV:	LD	HL,(PAGE)
	JR	EVAL_COUNT1
EVAL_TOPV:	LD	A,(IY)
	INC	IY			;SKIP "P"
	CP	'P'
	JP	NZ,SYNTAX		;"Syntax Error"
	CALL	GETTOP
	JR	EVAL_COUNT1
EVAL_ERLV:	LD	HL,(ERL)
	JR	EVAL_COUNT1
EVAL_ERRV:	LD	HL,(ERR)
	JR	EVAL_COUNT0
EVAL_COUNTV:	LD	HL,(COUNT)
EVAL_COUNT0:	LD	H,0
EVAL_COUNT1:	EXX
	XOR	A
	LD	C,A			;INTEGER MARKER
	LD	H,A
	LD	L,A
	RET
;
;OPENIN - Open a file for reading.
;OPENOUT - Open a file for writing.
;OPENUP - Open a file for reading or writing.
;Result is integer channel number (0 if error)
;
EVAL_OPENOT:	XOR	A
	DEFB	21H			;SKIP NEXT 2 BYTES
EVAL_OPENUP:	LD	A,2
	DEFB	21H			;SKIP NEXT 2 BYTES
EVAL_OPENIN:	LD	A,1
	PUSH	AF			;SAVE OPEN TYPE
	CALL	EVAL_ITEMS			;FILENAME
	LD	A,EVAL_CR
	LD	(DE),A
	POP	AF			;RESTORE OPEN TYPE
	ADD	A,-1			;AFFECT FLAGS
	LD	HL,ACCS
	CALL	OSOPEN
	LD	L,A
	JR	EVAL_COUNT0
;
;EXT - Return length of file.
;PTR - Return current file pointer.
;Results are integer numeric.
;
EVAL_EXT:	CALL	CHANEL
	CALL	GETEXT
	JR	EVAL_TIME0
;
EVAL_PTR:	CALL	CHANEL
	CALL	GETPTR
	JR	EVAL_TIME0
;
;TIME - Return current value of elapsed time.
;Result is integer numeric.
;
EVAL_TIMEV:	LD	A,(IY)
	CP	'$'
	JR	Z,EVAL_TIMEVS
	CALL	GETIME
EVAL_TIME0:	PUSH	DE
	EXX
	POP	HL
	XOR	A
	LD	C,A
	RET
;
;TIME$ - Return date/time string.
;Result is string
;
EVAL_TIMEVS:	INC	IY			;SKIP $
	CALL	GETIMS
	LD	A,80H			;MARK STRING
	RET
;
;String comparison:
;
EVAL_SLT:	CALL	SCP
	RET	NC
	JR	EVAL_TRUE
;
EVAL_SGT:	CALL	SCP
	RET	Z
	RET	C
	JR	EVAL_TRUE
;
EVAL_SGE:	CALL	SCP
	RET	C
	JR	EVAL_TRUE
;
EVAL_SLE:	CALL	SCP
	JR	Z,EVAL_TRUE
	RET	NC
	JR	EVAL_TRUE
;
EVAL_SNE:	CALL	SCP
	RET	Z
	JR	EVAL_TRUE
;
EVAL_SEQ:	CALL	SCP
	RET	NZ
EVAL_TRUE:	LD	A,-1
	EXX
	LD	H,A
	LD	L,A
	EXX
	LD	H,A
	LD	L,A
	INC	A
	LD	C,A
	RET
;
;PI - Return PI (3.141592654)
;Result is floating-point numeric.
;
EVAL_PI:	LD	A,35
	JR	EVAL_FPP1
;
;ABS - Absolute value
;Result is numeric, variable type.
;
EVAL_ABS:	LD	A,16
	JR	EVAL_FPPN
;
;NOT - Complement integer.
;Result is integer numeric.
;
EVAL_CPL:	LD	A,26
	JR	EVAL_FPPN
;
;DEG - Convert radians to degrees
;Result is floating-point numeric.
;
EVAL_DEG:	LD	A,21
	JR	EVAL_FPPN
;
;RAD - Convert degrees to radians
;Result is floating-point numeric.
;
EVAL_RAD:	LD	A,27
	JR	EVAL_FPPN
;
;SGN - Return -1, 0 or +1
;Result is integer numeric.
;
EVAL_SGN:	LD	A,28
	JR	EVAL_FPPN
;
;INT - Floor function
;Result is integer numeric.
;
EVAL_INT:	LD	A,23
	JR	EVAL_FPPN
;
;SQR - square root
;Result is floating-point numeric.
;
EVAL_SQR:	LD	A,30
	JR	EVAL_FPPN
;
;TAN - Tangent function
;Result is floating-point numeric.
;
EVAL_TAN:	LD	A,31
	JR	EVAL_FPPN
;
;COS - Cosine function
;Result is floating-point numeric.
;
EVAL_COS:	LD	A,20
	JR	EVAL_FPPN
;
;SIN - Sine function
;Result is floating-point numeric.
;
EVAL_SIN:	LD	A,29
	JR	EVAL_FPPN
;
;EXP - Exponential function
;Result is floating-point numeric.
;
EVAL_EXP:	LD	A,22
	JR	EVAL_FPPN
;
;LN - Natural log.
;Result is floating-point numeric.
;
EVAL_LN:	LD	A,24
	JR	EVAL_FPPN
;
;LOG - base-10 logarithm.
;Result is floating-point numeric.
;
EVAL_LOG:	LD	A,25
	JR	EVAL_FPPN
;
;ASN - Arc-sine
;Result is floating-point numeric.
;
EVAL_ASN:	LD	A,18
	JR	EVAL_FPPN
;
;ATN - arc-tangent
;Result is floating-point numeric.
;
EVAL_ATN:	LD	A,19
	JR	EVAL_FPPN
;
;ACS - arc-cosine
;Result is floating point numeric.
;
EVAL_ACS:	LD	A,17
EVAL_FPPN:	PUSH	AF
	CALL	EVAL_ITEMN
	POP	AF
EVAL_FPP1:	CALL	FPP
	JP	C,ERROR
	XOR	A
	RET
;
;SFIX - Convert to fixed-point notation
;
SFIX:	LD	A,38
	JR	EVAL_FPP1
;
;SFLOAT - Convert to floating-point notation
;
EVAL_SFLOAT:	LD	A,39
	JR	EVAL_FPP1
;
;VAL - Return numeric value of string.
;Result is variable type numeric.
;
EVAL_VAL:	CALL	EVAL_ITEMS
VAL0:	XOR	A
	LD	(DE),A
	LD	IX,ACCS
	LD	A,36
	JR	EVAL_FPP1
;
;EVAL - Pass string to expression evaluator.
;Result is variable type (numeric or string).
;
EVAL_EVAL:	CALL	EVAL_ITEMS
	LD	A,EVAL_CR
	LD	(DE),A
	PUSH	IY
	LD	DE,ACCS
	LD	IY,ACCS
	LD	C,0
	CALL	LEXAN2			;TOKENISE
	LD	(DE),A
	INC	DE
	XOR	A
	CALL	PUSHS			;PUT ON STACK
	LD	IY,2
	ADD	IY,SP
	CALL	EXPR
	POP	IY
	ADD	IY,SP
	LD	SP,IY			;ADJUST STACK POINTER
	POP	IY
	EX	AF,AF'
	RET
;
;RND - Random number function.
; RND gives random integer 0-&FFFFFFFF
; RND(-n) seeds random number & returns -n.
; RND(0) returns last value in RND(1) form.
; RND(1) returns floating-point 0-0.99999999.
; RND(n) returns random integer 1-n.
;
EVAL_RND:	LD	IX,RANDOM
	CALL	NXT
	CP	'('
	JR	Z,EVAL_RND5			;ARGUMENT FOLLOWS
	CALL	EVAL_LOAD5
EVAL_RND1:	RR	C
	LD	B,32
EVAL_RND2:	EXX	;CALCULATE NEXT
	ADC	HL,HL
	EXX
	ADC	HL,HL
	BIT	3,L
	JR	Z,EVAL_RND3
	CCF
EVAL_RND3:	DJNZ	EVAL_RND2
EVAL_RND4:	RL	C			;SAVE CARRY
	CALL	STORE5			;STORE NEW NUMBER
	XOR	A
	LD	C,A
	RET
EVAL_RND5:	CALL	ITEMI
	LD	IX,RANDOM
	BIT	7,H			;NEGATIVE?
	SCF
	JR	NZ,EVAL_RND4			;SEED
	CALL	TEST
	PUSH	AF
	LD	B,C
	EX	DE,HL
	EXX
	EX	DE,HL
	CALL	EVAL_LOAD5
	CALL	NZ,EVAL_RND1			;NEXT IF NON-ZERO
	EXX	;SCRAMBLE (CARE!)
	LD	C,7FH
EVAL_RND6:	BIT	7,H			;FLOAT
	JR	NZ,EVAL_RND7
	EXX
	ADD	HL,HL
	EXX
	ADC	HL,HL
	DEC	C
	JR	NZ,EVAL_RND6
EVAL_RND7:	RES	7,H			;POSITIVE 0-0.999999
	POP	AF
	RET	Z			;ZERO ARGUMENT
	EXX
	LD	A,E
	DEC	A
	OR	D
	EXX
	OR	E
	OR	D
	RET	Z			;ARGUMENT=1
	LD	B,0			;INTEGER MARKER
	LD	A,10
	CALL	FPP			;MULTIPLY
	JP	C,ERROR
	CALL	SFIX
	JP	EVAL_ADD1
;
;SUMLEN(array())
;
EVAL_SUMLEN:	INC	IY			;Skip LEN
	CALL	EVAL_GETARB
	BIT	7,B
	JP	Z,EVAL_MISMAT		;Type mismatch
	CALL	EVAL_ARRLEN
	PUSH	HL
	POP	IX			;IX addresses array
	XOR	A
	LD	H,A
	LD	L,A
	LD	B,A
EVAL_SUMLN1:	LD	C,(IX)
	ADD	HL,BC
	LD	C,4
	ADD	IX,BC
	DEC	DE			;Count elements
	LD	A,D
	OR	E
	JR	NZ,EVAL_SUMLN1
	JP	EVAL_COUNT1
;
;SUM(array())
;
EVAL_SUM:	CALL	NXT
	CP	EVAL_TLEN
	JR	Z,EVAL_SUMLEN
	CALL	EVAL_GETARB
	BIT	7,B
	JR	NZ,EVAL_SUMSTR
	PUSH	BC
	CALL	EVAL_ARRLEN
	PUSH	HL
	POP	IX			;IX addresses array
	CALL	ZERO
	POP	AF			;A = element size
EVAL_SUMUP:	PUSH	DE
	PUSH	AF
	CALL	EVAL_DLOADN
	LD	A,11 
	CALL	FPP
	JP	C,ERROR
	POP	AF
	LD	D,0
	LD	E,A
	ADD	IX,DE			;Bump to next element
	POP	DE
	DEC	DE			;Count elements
	LD	B,A
	LD	A,D
	OR	E
	LD	A,B
	JR	NZ,EVAL_SUMUP
	RET
;
;SUM(string array)
;
EVAL_SUMSTR:	CALL	EVAL_ARRLEN
	PUSH	HL
	POP	IX			;IX addresses array
	EX	DE,HL
	LD	DE,ACCS
	LD	B,0
EVAL_SUMST1:	PUSH	HL
	LD	C,(IX)
	LD	A,C
	OR	A
	JR	Z,EVAL_SUMST2
	ADD	A,E
	LD	A,19
	JP	C,ERROR			;"String too long"
	LD	L,(IX+2)
	LD	H,(IX+3)
	LDIR
EVAL_SUMST2:	POP	HL
	LD	C,4
	ADD	IX,BC
	DEC	HL			;Count elements
	LD	A,H
	OR	L
	JR	NZ,EVAL_SUMST1
	OR	80H
	RET
;
;MOD(array())
;
EVAL_MODFUN:	CALL	EVAL_GETARB
	BIT	7,B
	JP	NZ,EVAL_MISMAT
	PUSH	BC
	CALL	EVAL_ARRLEN
	PUSH	HL
	POP	IX			;IX addresses array
	CALL	ZERO
	POP	AF			;A = element size
EVAL_MODUP:	PUSH	DE
	PUSH	AF
	PUSH	BC
	PUSH	HL
	EXX
	PUSH	HL
	EXX
	CALL	LOADN
	XOR	A
	LD	B,A
	LD	D,A
	LD	E,A
	EXX
	LD	D,A
	LD	E,2
	EXX
	LD	A,14
	PUSH	IX
	CALL	FPP			;Square
	POP	IX
	JP	C,ERROR
	EXX
	EX	DE,HL
	POP	HL
	EXX
	EX	DE,HL
	POP	HL
	LD	A,C
	POP	BC
	LD	B,A
	LD	A,11 
	CALL	FPP			;Accumulate
	JP	C,ERROR
	POP	AF
	LD	D,0
	LD	E,A
	ADD	IX,DE			;Bump to next element
	POP	DE
	DEC	DE			;Count elements
	LD	B,A
	LD	A,D
	OR	E
	LD	A,B
	JR	NZ,EVAL_MODUP
	LD	A,30
	CALL	FPP			;Square root
	XOR	A
	RET
;
;INSTR - String search.
;Result is integer numeric.
;
EVAL_INSTR:	CALL	EXPRS			;STRING TO SEARCH
	CALL	COMMA
	CALL	PUSHS			;SAVE STRING ON STACK
	CALL	EXPRS			;SUB-STRING
	POP	BC
	LD	HL,0
	ADD	HL,SP			;HL ADDRESSES MAIN
	PUSH	BC			;C = MAIN STRING LENGTH
	LD	B,E			;B = SUB-STRING LENGTH
	CALL	NXT
	CP	','
	LD	A,0
	JR	NZ,EVAL_INSTR1
	INC	IY			;SKIP COMMA
	PUSH	BC			;SAVE LENGTHS
	PUSH	HL			;SAVE MAIN ADDRESS
	CALL	PUSHS
	CALL	EXPRI
	POP	BC
	CALL	POPS
	POP	HL			;RESTORE MAIN ADDRESS
	POP	BC			;RESTORE LENGTHS
	EXX
	LD	A,L
	EXX
	OR	A
	JR	Z,EVAL_INSTR1
	DEC	A
EVAL_INSTR1:	LD	DE,ACCS			;DE ADDRESSES SUB
	CALL	SEARCH
	POP	DE
	JR	Z,EVAL_INSTR2		;N.B. CARRY CLEARED
	SBC	HL,HL
	ADD	HL,SP
EVAL_INSTR2:	SBC	HL,SP
	EX	DE,HL
	LD	H,0
	ADD	HL,SP
	LD	SP,HL
	EX	DE,HL
	CALL	BRAKET
	JP	EVAL_COUNT1
;
;SEARCH - Search string for sub-string
;   Inputs: Main string at HL length C
;           Sub-string at DE length B
;           Starting offset A
;  Outputs: NZ - not found
;           Z - found at location HL-1
;           Carry always cleared
;
SEARCH:	PUSH	BC
	LD	B,0
	LD	C,A
	ADD	HL,BC			;NEW START ADDRESS
	POP	BC
	SUB	C
	JR	NC,EVAL_SRCH4
	NEG
	LD	C,A			;REMAINING LENGTH
EVAL_SRCH1:	LD	A,(DE)
	PUSH	BC
	LD	B,0
	CPIR	;FIND FIRST CHARACTER
	LD	A,C
	POP	BC
	JR	NZ,EVAL_SRCH4
	LD	C,A
	DEC	B			;Bug fix
	CP	B			;Bug fix
	INC	B			;Bug fix
	JR	C,EVAL_SRCH4			;Bug fix
	PUSH	BC
	PUSH	DE
	PUSH	HL
	DEC	B
	JR	Z,EVAL_SRCH3			;FOUND !
EVAL_SRCH2:	INC	DE
	LD	A,(DE)
	CP	(HL)
	JR	NZ,EVAL_SRCH3
	INC	HL
	DJNZ	EVAL_SRCH2
EVAL_SRCH3:	POP	HL
	POP	DE
	POP	BC
	JR	NZ,EVAL_SRCH1
	XOR	A			;Z, NC
	RET	;FOUND
;
EVAL_SRCH4:	OR	0FFH			;NZ, NC
	RET	;NOT FOUND
;
;CHR$ - Return character with given ASCII value.
;Result is string.
;
EVAL_CHRS:	CALL	ITEMI
	EXX
	LD	A,L
	JR	EVAL_GET1
;
;GET$ - Return key pressed as string, or read from file
;Result is string.
;
EVAL_GETS:	CALL	NXT
	CP	'#'
	JR	Z,EVAL_GET2
	CALL	OSRDCH
EVAL_GET1:	SCF
	JR	EVAL_INKEY1
;
EVAL_GET2:	CALL	CHNL			;File channel
	CALL	NXT
	CP	EVAL_TBY
	JR	Z,EVAL_GET3
	CP	EVAL_TTO
	JR	NZ,EVAL_GET4
EVAL_GET3:	INC	IY
	PUSH	AF
	PUSH	DE
	CALL	ITEMI			;Get BY or TO qualifier
	EXX
	LD	B,H
	LD	C,L
	POP	DE
	POP	AF
EVAL_GET4:	LD	HL,ACCS
	CP	EVAL_TTO
	JR	Z,EVAL_GET5
	LD	D,C			;Maximum count
	LD	BC,100H			;Default
	CP	EVAL_TBY
	JR	Z,EVAL_GET6
EVAL_GET5:	LD	D,0
	SET	1,B			;Flag no count
EVAL_GET6:	PUSH	BC
	CALL	OSBGET
	POP	BC
	BIT	1,B
	JR	Z,EVAL_GET10
	CP	C
	JR	Z,EVAL_GET9			;NUL (or supplied term)
	BIT	7,B
	JR	NZ,EVAL_GET7
	BIT	0,B
	JR	Z,EVAL_GET8
	CP	EVAL_LF
	JR	Z,EVAL_GET9			;LF
EVAL_GET7:	CP	EVAL_CR
	JR	Z,EVAL_GET9			;CR
EVAL_GET8:	OR	A
EVAL_GET10:	LD	(HL),A
	INC	L
	DEC	D
	JR	C,EVAL_GET9			;EOF
	JR	NZ,EVAL_GET6
EVAL_GET9:	EX	DE,HL
	LD	A,80H
	RET
;
;INKEY$ - Wait up to n centiseconds for keypress.
; Return key pressed as string or null
; string if time elapsed.
;Result is string.
;
EVAL_INKEYS:	CALL	ITEMI
	EXX
	CALL	OSKEY
EVAL_INKEY1:	LD	DE,ACCS
	LD	(DE),A
	LD	A,80H
	RET	NC
	INC	E
	RET
;
;MID$ - Return sub-string.
;Result is string.
;
EVAL_MIDS:	CALL	EXPRS
	CALL	COMMA
	CALL	PUSHS			;SAVE STRING ON STACK
	CALL	EXPRI
	POP	BC
	CALL	POPS
	EXX
	LD	A,L
	EXX
	OR	A
	JR	Z,EVAL_MIDS1
	DEC	A
	LD	L,A
	SUB	E
	LD	E,0
	JR	NC,EVAL_MIDS1
	NEG
	LD	C,A
	CALL	EVAL_RIGHT1
EVAL_MIDS1:	CALL	NXT
	CP	','
	JR	Z,EVAL_LEFT1
	CALL	BRAKET
	LD	A,80H
	RET
;
;LEFT$ - Return left part of string.
;Carry cleared if entire string returned.
;Result is string.
;
EVAL_LEFTS:	CALL	EXPRS
	CALL	NXT
	CP	','
	JR	Z,EVAL_LEFT1
	CALL	BRAKET
	LD	A,E
	OR	A
	JR	Z,EVAL_LEFT3
	DEC	E
	JR	EVAL_LEFT3
;
EVAL_LEFT1:	INC	IY
	CALL	PUSHS			;SAVE STRING ON STACK
	CALL	EXPRI
	POP	BC
	CALL	POPS
	CALL	BRAKET
	EXX
	LD	A,L
	EXX
	CP	E
	JR	NC,EVAL_LEFT3
	LD	L,E			;FOR RIGHT$
EVAL_LEFT2:	LD	E,A
EVAL_LEFT3:	LD	A,80H			;STRING MARKER
	RET
;
;RIGHT$ - Return right part of string.
;Result is string.
;
EVAL_RIGHTS:	CALL	EXPRS
	CALL	NXT
	CP	','
	JR	Z,EVAL_RIGHT0
	CALL	BRAKET
	LD	A,E
	OR	A
	JR	Z,EVAL_LEFT3
	DEC	A
	LD	C,1
	JR	EVAL_RIGHT2
;
EVAL_RIGHT0:	CALL	EVAL_LEFT1
	RET	NC
	INC	E
	DEC	E
	RET	Z
	LD	C,E
	LD	A,L
	SUB	E
EVAL_RIGHT2:	LD	L,A
EVAL_RIGHT1:	LD	B,0
	LD	H,D
	LD	E,B
	LDIR	;MOVE
	LD	A,80H
	RET
;
;STRING$ - Return n concatenations of a string.
;Result is string.
;
EVAL_STRING:	CALL	EXPRI
	CALL	COMMA
	EXX
	LD	A,L
	EXX
	PUSH	AF
	CALL	EXPRS
	CALL	BRAKET
	POP	AF
	OR	A
	JR	Z,EVAL_LEFT2			;N=0
	DEC	A
	LD	C,A
	LD	A,80H			;STRING MARKER
	RET	Z
	INC	E
	DEC	E
	RET	Z			;NULL STRING
	LD	B,E
	LD	H,D
	LD	L,0
EVAL_STRIN1:	PUSH	BC
EVAL_STRIN2:	LD	A,(HL)
	INC	HL
	LD	(DE),A
	INC	E
	LD	A,19
	JP	Z,ERROR			;"String too long"
	DJNZ	EVAL_STRIN2
	POP	BC
	DEC	C
	JR	NZ,EVAL_STRIN1
	LD	A,80H
	RET
;
;SUBROUTINES
;
;TEST - Test HLH'L' for zero
;  Outputs: Z-flag set & A=0 if zero
; Destroys: A,F
;
TEST:	LD	A,H
	OR	L
	EXX
	OR	H
	OR	L
	EXX
	RET
;
;DECODE - Decode line number in pseudo-binary.
;   Inputs: IY = Text pointer.
;  Outputs: HL=0, H'L'=line number, C=0.
; Destroys: A,C,H,L,H',L',IY,F
;
DECODE:	EXX
	LD	A,(IY)
	INC	IY
	RLA
	RLA
	LD	H,A
	AND	0C0H
	XOR	(IY)
	INC	IY
	LD	L,A
	LD	A,H
	RLA
	RLA
	AND	0C0H
	XOR	(IY)
	INC	IY
	LD	H,A
	EXX
	XOR	A
	LD	C,A
	LD	H,A
	LD	L,A
	RET
;
;HEXSTR - convert numeric value to HEX string.
;   Inputs: HLH'L'C = integer or floating-point number
;  Outputs: String in string accumulator.
;           E = string length. D = ACCS/256
;
EVAL_HEXSTS:	INC	IY			;SKIP TILDE
	CALL	EVAL_ITEMN
	CALL	HEXSTR
	LD	A,80H
	RET
;
HEXSTR:	CALL	SFIX
	LD	BC,8
	LD	DE,ACCS
EVAL_HEXST1:	PUSH	BC
	LD	B,4
	XOR	A
EVAL_HEXST2:	EXX
	ADD	HL,HL
	EXX
	ADC	HL,HL
	RLA
	DJNZ	EVAL_HEXST2
	POP	BC
	DEC	C
	RET	M
	JR	Z,EVAL_HEXST3
	OR	A
	JR	NZ,EVAL_HEXST3
	CP	B
	JR	Z,EVAL_HEXST1
EVAL_HEXST3:	ADD	A,90H
	DAA
	ADC	A,40H
	DAA
	LD	(DE),A
	INC	DE
	LD	B,A
	JR	EVAL_HEXST1
;
;Function STR - convert numeric value to ASCII string.
;   Inputs: HLH'L'C = integer or floating-point number.
;  Outputs: String in string accumulator.
;           E = length, D = ACCS/256
;           A = 80H (type=string)
;
;First normalise for decimal output:
;
EVAL_STRS:	CALL	NXT
	CP	'~'
	JR	Z,EVAL_HEXSTS
	CALL	EVAL_ITEMN
	LD	IX,STAVAR
	LD	A,(IX+3)
	OR	A
	LD	IX,EVAL_G9-1			;G9 FORMAT
	JR	Z,EVAL_STR0
STR:	LD	IX,STAVAR
EVAL_STR0:	LD	DE,ACCS
	LD	A,37
	CALL	FPP
	JP	C,ERROR
	BIT	0,(IX+2)
EVAL_STR1:	LD	A,80H			;STRING MARKER
	RET	Z
	LD	A,C
	ADD	A,4
EVAL_STR2:	CP	E
	JR	Z,EVAL_STR1
	EX	DE,HL
	LD	(HL),' '		;TRAILING SPACE
	INC	HL
	EX	DE,HL
	JR	EVAL_STR2
;
EVAL_G9:	DEFW	9
;
;STRING COMPARE
;Compare string (DE) length B with string (HL) length C.
;Result preset to false.
;
SCP:	CALL	EVAL_SCP0
ZERO:	LD	A,0
	EXX
	LD	H,A
	LD	L,A
	EXX
	LD	H,A
	LD	L,A
	LD	C,A
	RET
;
EVAL_SCP0:	INC	B
	INC	C
EVAL_SCP1:	DEC	B
	JR	Z,EVAL_SCP2
	DEC	C
	JR	Z,EVAL_SCP3
	LD	A,(DE)
	CP	(HL)
	RET	NZ
	INC	DE
	INC	HL
	JR	EVAL_SCP1
EVAL_SCP2:	OR	A
	DEC	C
	RET	Z
	SCF
	RET
EVAL_SCP3:	OR	A
	INC	C
	RET
;
;PUSH$ - SAVE STRING ON STACK.
;   Inputs: String in string accumulator.
;           E = string length.
;           A - saved on stack.
; Destroys: B,C,D,E,H,L,IX,SP,F
;
PUSHS:	LD	HL,ACCS
	CALL	CHECK
	POP	IX			;RETURN ADDRESS
	OR	A			;CLEAR CARRY
	LD	D,H
	LD	C,E
	SBC	HL,DE
	ADD	HL,SP
	LD	SP,HL
	LD	B,A
	PUSH	BC
	JR	Z,EVAL_PUSHS1		;ZERO LENGTH
	EX	DE,HL
	LD	B,0
	LD	L,B			;L=0
	LDIR	;COPY TO STACK
	CALL	CHECK
EVAL_PUSHS1:	JP	(IX)			;"RETURN"
;
;POP$ - RESTORE STRING FROM STACK.
;   Inputs: C = string length.
;  Outputs: String in string accumulator.
;           E = string length.
; Destroys: B,C,D,E,H,L,IX,SP,F
;
POPS:	POP	IX			;RETURN ADDRESS
	LD	HL,0
	LD	B,H			;B=0
	ADD	HL,SP
	LD	DE,ACCS
	INC	C
	DEC	C
	JR	Z,EVAL_POPS1			;ZERO LENGTH
	LDIR	;COPY FROM STACK
EVAL_POPS1:	LD	SP,HL
	JP	(IX)			;"RETURN"
;
EVAL_BINDIG:	LD	A,(IY)
	CP	'0'
	RET	C
	CP	'1'+1
	CCF
	RET	C
	SUB	'0'
	RET
;
EVAL_HEXDIG:	LD	A,(IY)
	CP	'0'
	RET	C
	CP	'9'+1
	CCF
	RET	NC
	CP	'A'
	RET	C
	SUB	'A'-10
	CP	16
	CCF
	RET
;
EVAL_RELOPQ:	CP	'>'
	RET	NC
	CP	'='
	RET	NC
	CP	'<'
	RET
;
EVAL_SAVE:	INC	IY
	AND	0FH
EVAL_SAVE1:	EX	AF,AF'
	JP	M,EVAL_MISMAT
	EX	AF,AF'
	EX	(SP),HL
	EXX
	PUSH	HL
	EXX
	PUSH	AF
	PUSH	BC
	JP	(HL)
;
EVAL_DOIT:	EX	AF,AF'
	JP	M,EVAL_MISMAT
	EXX
	POP	BC			;RETURN ADDRESS
	EXX
	LD	A,C
	POP	BC
	LD	B,A
	POP	AF			;OPERATOR
	EXX
	EX	DE,HL
	POP	HL
	EXX
	EX	DE,HL
	POP	HL
	EXX
	PUSH	BC
	EXX
	CALL	FPP
	JR	C,EVAL_ERROR1
	XOR	A
	EX	AF,AF'			;TYPE
	LD	A,(IY)
	RET
;
COMMA:	CALL	NXT
	INC	IY
	CP	','
	RET	Z
	LD	A,5
	JR	EVAL_ERROR1			;"Missing ,"
;
BRAKET:	CALL	NXT
	INC	IY
	CP	')'
	RET	Z
	LD	A,27
EVAL_ERROR1:	JP	ERROR			;"Missing )"
;
EVAL_DISPT2:	PUSH	HL
	LD	HL,EVAL_SOPTBL
	JR	EVAL_DISPT0
;
EVAL_DISPAT:	PUSH	HL
	SUB	EVAL_FUNTOK
	LD	HL,EVAL_FUNTBL
EVAL_DISPT0:	PUSH	BC
	ADD	A,A
	LD	C,A
	LD	B,0
	ADD	HL,BC
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	POP	BC
	EX	(SP),HL
	RET	;OFF TO ROUTINE
;
EVAL_STOREA:	LD	A,D
	PUSH	DE
	PUSH	HL
	EX	(SP),IX
	OR	A
	JP	M,EVAL_STORA1
	CALL	LOADN
	EX	(SP),IX
	CALL	MODIFY
	POP	HL
	POP	DE
	LD	C,D
	LD	B,0
	RET
;
EVAL_STORA1:	PUSH	DE
	CALL	LOADS
	POP	HL
	EX	(SP),IX
	CALL	MODIFS
	POP	HL
	POP	DE
	LD	BC,4
	RET
;
; Assign to whole array:
; array1() = array expression
; array1() = n1,n2,n3,n4...
; array1() = n (n copied into all elements)
;
; Inputs: D = type (65, 68, 69, 193)
;         E = opcode ('=' for store, '+','-' etc. for modify)
;         HL = IX = VARPTR
;         IY = text pointer
;
LETARR:	RES	6,D			;Lose array marker
	PUSH	DE			;Save type & opcode
	CALL	EVAL_GETAR1			;Get and check indirect link
	CALL	EVAL_ARRLEN			;DE = elements, HL addresses first
	POP	BC
	LD	A,B			;A = type
	PUSH	DE
	PUSH	BC
	PUSH	HL
	CALL	X14OR5			;DE = size in bytes
	LD	B,D
	LD	C,E
	POP	IX
	POP	DE
;
; (SP) = number of elements
; BC = size in bytes
; DE = type & opcode
; IX = address of first element
;
; allocate space on stack and zero it:
;
	XOR	A			;Clear carry and zero error code
	SBC	HL,HL
	ADD	HL,SP			;HL = SP
	SBC	HL,BC
	JR	C,EVAL_ERROR1		;'No room'
	PUSH	BC
	LD	BC,(FREE)
	INC	B			;Safety margin
	SBC	HL,BC
	ADD	HL,BC
	POP	BC
	JR	C,EVAL_ERROR1		;'No room'
	LD	SP,HL	
EVAL_LETA0:	LD	(HL),0
	INC	HL
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,EVAL_LETA0		;Clear allocated stack
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	LD	H,A
	LD	L,A
	ADD	HL,SP
;
;	CALL	NXT
;	CP	TEVAL		;;EVAL not currently supported
;
	CALL	EVAL_EXPRA
	LD	SP,HL			;Update stack pointer
	POP	BC			;Level stack
	JP	XEQ
;
; EXPRA - Evaluate array expression, strictly left-to-right;
; Note: String array arithmetic (concatenation) is not supported
; because it would require a way of recovering freed string space.
;
;   Inputs: BC = number of elements
;           DE = type & opcode
;           HL = address of temporary stack space
;           IX = address of first element of array
;  Outputs: HL = value to set stack pointer to
;
EVAL_EXPRA:	LD	A,'='
	DEC	IY
EVAL_EXPRA1:	INC	IY
	PUSH	DE
	PUSH	BC
	PUSH	HL
	PUSH	IX
	LD	E,A			;Operator
	CALL	EVAL_ITEMA
	POP	IX
	POP	HL
	POP	BC
	POP	DE
	CALL	NXT
	CP	','			;List?
	JR	Z,EVAL_EXPRA3
	CALL	TERMQ
	JR	NZ,EVAL_EXPRA1
;
; Update destination array from stack:
;
EVAL_EXPRA2:	PUSH	BC
	CALL	EVAL_STOREA			;(IX) <- (HL)
	ADD	HL,BC
	ADD	IX,BC
	POP	BC
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,EVAL_EXPRA2
	RET
;
; Update destination array from list (n.b. not transferred via stack):
;
EVAL_EXPRA3:	PUSH	BC
	CALL	EVAL_STOREA			;(IX) <- (HL)
EVAL_EXPRA4:	INC	IY			;Bump past comma
	ADD	HL,BC
	ADD	IX,BC
	POP	BC
	DEC	BC
	LD	A,B
	OR	C
	RET	Z
	PUSH	BC
	PUSH	DE
	PUSH	HL
	PUSH	IX
	BIT	7,D
	JR	NZ,EVAL_EXPRA5
	PUSH	DE
	CALL	EXPRN
	POP	DE
	POP	IX
	PUSH	IX
	CALL	MODIFY
	JR	EVAL_EXPRA6
;
EVAL_EXPRA5:	PUSH	DE
	CALL	EXPRS
	POP	HL
	POP	IX
	PUSH	IX
	CALL	MODIFS
EVAL_EXPRA6:	POP	IX
	POP	HL
	POP	DE
	LD	BC,4
	BIT	7,D
	JR	NZ,EVAL_EXPRA7
	LD	C,D
EVAL_EXPRA7:	CALL	NXT
	CP	','
	JR	Z,EVAL_EXPRA4
	POP	DE
EVAL_EXPRA8:	ADD	HL,BC			;Skip remaining elements
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,EVAL_EXPRA8
	RET
;
; ITEMA: evaluate and operate on array item
;   Inputs: D = type
;           E = operator ('=' for first item)
;           BC = number of elements
;           HL = pointer to destination on stack
;           IY = text pointer
;  Outputs: IY updated
; Destroys: Everything except SP
;
EVAL_ITEMA:	CALL	NXT
	PUSH	HL			;Pointer to destination
	PUSH	BC			;Number of elements
	PUSH	IY			;In case normal expression
	PUSH	DE			;Ditto
	CP	'-'
	JR	NZ,EVAL_ITEMA1		;Not unary minus
	LD	A,E
	CP	'='
	JR	NZ,EVAL_ITEMA1		;Not unary minus
	INC	IY			;Bump past '-'
	CALL	NXT
	LD	E,'-'			;Unary minus
EVAL_ITEMA1:	PUSH	DE			;Type and operator
	CALL	GETVAR
	POP	DE			;Type & operator
	JR	NZ,EVAL_ITEMA4		;Non-array expression
	BIT	6,A
	JR	Z,EVAL_ITEMA4		;Not a whole array
	POP	BC			;Junk saved original op
	POP	BC			;Junk saved text pointer
	RES	6,A
	CP	D
	JP	NZ,EVAL_MISMAT		;'Type mismatch'
	PUSH	DE			;Save type & operator again
	CALL	EVAL_GETAR1
	CALL	EVAL_ARRLEN
	LD	B,D			;BC = number of elements
	LD	C,E
	POP	DE			;Restore type & operator
	EX	(SP),HL
	CALL	NXT
	POP	IX			;Pointer to source
	CP	'.'
	JP	Z,EVAL_ARRDOT		;Dot product
	OR	A
	SBC	HL,BC			;Same number of elements?
	JP	NZ,EVAL_MISMAT		;'Type mismatch'	
	POP	HL			;Pointer to destination
	BIT	7,D
	JR	NZ,EVAL_ITEMA3
;
; Process numeric array item:
;
EVAL_ITEMA2:	PUSH	BC
	PUSH	HL
	LD	A,D
	CALL	LOADN
	EX	(SP),IX
	PUSH	DE
	CALL	MODIFY
	POP	DE
	EX	(SP),IX
	POP	HL
	LD	C,D
	LD	B,0
	ADD	IX,BC
	ADD	HL,BC
	POP	BC
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,EVAL_ITEMA2
	RET
;
; Process string array item (just copy descriptors):
;
EVAL_ITEMA3:	EX	DE,HL			;DE = destination
	LD	H,B
	LD	L,C
	ADD	HL,HL
	ADD	HL,HL
	LD	B,H
	LD	C,L
	PUSH	IX
	POP	HL			;HL = source
	LDIR
	RET
;
; Process numeric non-array item:
;
EVAL_ITEMA4:	POP	DE			;Restore original operator
	POP	IY			;Restore original text pointer
	BIT	7,D
	JR	NZ,EVAL_ITEMA5
	PUSH	DE
	CALL	EVAL_EXPR45			;; should be EXP345
	LD	A,C			;Exponent
	POP	DE			;Type / operator
	POP	BC			;Count
	POP	IX
EVAL_ITEMA7:	PUSH	HL
	PUSH	BC
	PUSH	DE
	EXX
	PUSH	HL
	EXX
	PUSH	AF
	LD	C,A
	CALL	MODIFY
	POP	AF
	EXX
	POP	HL
	EXX
	POP	DE
	LD	C,D
	LD	B,0
	ADD	IX,BC
	POP	BC
	DEC	BC
	SBC	HL,HL
	SBC	HL,BC
	POP	HL
	JR	NZ,EVAL_ITEMA7		;Copy into every element!
	RET
;
; Process string non-array item:
;
EVAL_ITEMA5:	CALL	EXPRS
	LD	A,E
	OR	A
	JR	Z,EVAL_ITEMA0
	LD	HL,ACCS
	LD	DE,BUFFER
	LD	C,A
	LD	B,0
	LDIR
EVAL_ITEMA0:	POP	BC
	POP	IX
	EXX
	LD	L,A
	EXX
	LD	DE,4
	LD	HL,BUFFER
EVAL_ITEMA6:	CALL	STORE4
	ADD	IX,DE
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,EVAL_ITEMA6		;Copy into every element!
	RET
;
; Array dot-product:
;
EVAL_ARRDOT:	INC	IY			;Bump past dot
	LD	A,D			;Type
	OR	A
	JP	M,EVAL_MISMAT		;'Type mismatch'
	EX	DE,HL
	POP	HL
;
; A = type
; DE = no. of elements in destination array (outer loop counter)
; IX = pointer to first source array data
; HL = pointer to destination data
; IY = text pointer
;
	PUSH	DE
	PUSH	HL
	PUSH	IX
	PUSH	AF
	CALL	EVAL_GETARR
	CALL	EVAL_ARRLEN
	POP	AF
	EX	DE,HL
	LD	L,(IX)
	LD	H,(IX+1)		;Indirect pointer
	LD	L,(HL)			;No. of dimensions
	DEC	L
	EX	DE,HL
	POP	IX
	POP	BC
	POP	DE
;
	PUSH	IY			;Save text pointer
	PUSH	BC			;Save destination pointer
	PUSH	HL
	POP	IY
;
; Get row counts:
;
	LD	HL,1
	JR	Z,EVAL_ARR1D
	LD	H,(IY-1)
	LD	L,(IY-2)
EVAL_ARR1D:	PUSH	DE
	EX	DE,HL
	CALL	X14OR5
	EX	DE,HL
	POP	DE
	LD	B,(IX-1)
	LD	C,(IX-2)
;
; A = type, Z-flag set if first array is one-dimensional
; BC = no. of rows of first source array (inner loop counter)
; DE = no. of elements in destination array (outer loop counter)
; HL = no. of rows of second source array * size of each element
; IX = pointer to first source array
; IY = pointer to second source array
; (SP) = pointer to destination data
;
; Dot-product outer loop:
;
EVAL_OUTER:	PUSH	BC			;1
	PUSH	DE			;2
	PUSH	HL			;3
	PUSH	IX			;4
	PUSH	IY			;5
	LD	D,B
	LD	E,C
	PUSH	AF
	CALL	ZERO			;Zero accumulator
	POP	AF
EVAL_INNER:	PUSH	DE			;6
	PUSH	BC			;Save accumulator
	PUSH	HL
	EXX
	PUSH	HL
	EXX
;
	CALL	LOADN			;Load from (IX)
	PUSH	IX
	EX	(SP),IY
	POP	IX
;
	CALL	EVAL_DLOADN			;Load from (IY)
	PUSH	IX
	EX	(SP),IY
	POP	IX
;
	PUSH	AF
	LD	A,10
	CALL	FPP			;Multiply
	JP	C,ERROR
	POP	AF
;
	EXX	;Restore accumulator
	EX	DE,HL
	POP	HL
	EXX
	EX	DE,HL
	POP	HL
	EX	AF,AF'
	LD	A,C
	POP	BC
	LD	B,A
	EX	AF,AF'
;
	PUSH	AF
	LD	A,11
	CALL	FPP			;Accumulate
	JP	C,ERROR
	POP	AF
;
; Bump pointers:
;
	POP	DE			;5
;
	EXX
	LD	C,A
	LD	B,0
	ADD	IX,BC
	POP	DE
	POP	BC
	EX	(SP),HL
	EX	DE,HL
	ADD	IY,DE
	EX	DE,HL
	EX	(SP),HL
	PUSH	BC
	PUSH	DE
	EXX
;
; Count inner loops:
;
	DEC	DE			;Inner loop counter
	INC	E
	DEC	E
	JR	NZ,EVAL_INNER
	INC	D
	DEC	D
	JR	NZ,EVAL_INNER
;
	POP	IY			;4
	POP	IX			;3
;
; Swap pointers:
;
	EXX
	EX	AF,AF'
	POP	AF
	POP	BC
	POP	DE
	EX	(SP),IX
	PUSH	DE
	PUSH	BC
	PUSH	AF
	EX	AF,AF'
	EXX
;
; Save to destination array and bump pointer:
;
	PUSH	AF
	PUSH	DE
	CALL	STOREN
	POP	DE
	POP	AF
	LD	C,A
	LD	B,0
	ADD	IX,BC
;
; Swap pointers:
;
	EXX
	EX	AF,AF'
	POP	AF
	POP	BC
	POP	DE
	EX	(SP),IX
	PUSH	DE
	PUSH	BC
	PUSH	AF
	EX	AF,AF'
	EXX
;
	POP	HL			;2
	POP	DE			;1 Outer loop counter
	POP	BC			;0
	DEC	DE			;Count outer loops
;
; Adjust IX & IY
;
	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	C,A
	LD	B,0
	ADD	IY,BC
	PUSH	AF
	PUSH	HL
	CALL	X14OR5
	POP	BC
	CALL	EVAL_MOD16
	POP	AF
	OR	A
	LD	BC,0
	SBC	HL,BC
	POP	HL
	POP	DE
	POP	BC
	JR	NZ,EVAL_MODNZ
	PUSH	DE
	PUSH	HL
	EX	DE,HL
	PUSH	IY
	POP	HL
	OR	A
	SBC	HL,DE
	PUSH	HL
	POP	IY
	LD	D,B
	LD	E,C
	CALL	X14OR5
	ADD	IX,DE
	POP	HL
	POP	DE
EVAL_MODNZ:
;
; Count outer loops:
;
	INC	E
	DEC	E
	JP	NZ,EVAL_OUTER
	INC	D
	DEC	D
	JP	NZ,EVAL_OUTER
;
; Exit:
;
	POP	HL
	POP	IY
	RET
;
; HL = DE MOD BC
;
EVAL_MOD16:	XOR	A
	LD	H,A
	LD	L,A
	LD	A,17
EVAL_MOD160:	SBC	HL,BC
	JR	NC,EVAL_MOD161
	ADD	HL,BC
EVAL_MOD161:	CCF
	RL	E
	RL	D
	DEC	A
	RET	Z
	ADC	HL,HL
	JR	EVAL_MOD160
;

