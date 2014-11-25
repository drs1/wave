;;; emulator for warm - phase 2
;;; (c) d.r.smith modsoussi bijan
	.requ	wpc, r15
	.requ	ci, r14
	.requ	op, r13
	.requ	src, r12
	.requ	dst, r11
	.requ 	rhs, r10
	.requ	shiftC, r9
	.requ	cond, r8
	.requ	work0, r0
 	.requ	work1, r1
		
 	.equ	maskT, 0xc000000 	;27 and 26th bit
	.equ	maskA, 0x7800		;1 in 14,13,12th bit
	.equ	maskShift, 0x3F
	.equ	mask4, 0xf
	.equ	maskValue, 0x1ff
	.equ	maskExp, 0x1f00
	
	lea	WARM,work0
	lea	REGS, cond
	trap	$SysOverlay
	
;;; get the instruction
fetch:	mov	WARM(wpc),ci
 	mov	$maskT, work0	;decipher type
	and	ci, work0
	shr	$31, work0	;work 0 holds the type
 	mov	TYPE(work0), rip ;jump on type

;;; types of instructions
	
arith:	mov 	ci,op
	shl	$4,op
	shr	$27,op
	mov 	$maskA, work0
	and 	ci,work0
	shr	$12, work0	;work 0 holds the addressing mode
	mov     ci, src		;get dst and src
	shr     $15, src
	and     $mask4, src
	mov     ci, dst
	shr     $19, dst
	and     $mask4, dst
	mov	ADDR(work0), rip
ls:
branch:	
	
;;; Immediate Mode
imd:	mov	ci, work0
	and	$maskExp, work0	;exponent
	shr	$9, work0
	mov	ci, rhs
	and	$maskValue, rhs	;value
	shl	work0, rhs	;shifted value in rhs
	mov     INSTR(op), rip

;;; Register Shifted by Immediate Mode
rim:	mov	ci, rhs
	shl	$22, rhs
	shr	$28, rhs 	;now we have src reg 2 in rhs
	mov	REGS(rhs), rhs	;rhs now has the value that was in register number rhs
	mov	ci, shiftC
	and	$maskShift, shiftC	;shift count has the bits number to shift
	mov	ci, work0
	shl	$20, work0
	shr	$30, work0	;work1 now has the shop
	mov 	SHOP(work0),rip
	
;;; Register Shifted by Register Mode;;;
	
rsr:	mov	$mask4, shiftC	; shiftC := 15
	and 	ci, shiftC	; shiftC := shiftC & ci; to get shift register
	mov	REGS(shiftC), shiftC ; shiftC now has whatever was stored in the 
	mov	ci, rhs	
	shl	$22, rhs
	shr	$28, rhs	; rhs has rhs register
	mov	REGS(rhs), rhs	; rhs now has whatever was stored in rhs (memory)
	mov 	ci, work0
	shl	$20, work0
	shr	$30, work0	; work0 now has the shift op code
	mov	SHOP(work0), rip
	
;;; logical shift left
	
lsl:	shl	shiftC, rhs
	mov     INSTR(op), rip
	
;;; logical shift right
lsr:	shr	shiftC, rhs
	mov     INSTR(op), rip
	
;;; arithmetic shift right

asr:	sar	shiftC, rhs
	mov     INSTR(op), rip

;;; rotate right shift
	
ror:	mov	rhs, work0
	mov	$32, work1	
	sub	shiftC, work1	;work1 := 32-shr
	shl	work1, work0	;work1 is low shr bits shifted (32-shr) to the left
	shr	shiftC, rhs	;work2 is the highest (32-shr) bits shifted shr to the right
	add	work0, rhs
	mov     INSTR(op), rip

;;; Register Product Mode
	
rpm:	mov	$mask4, work0
	and	ci, work0	; work0 now has src reg 3
	mov	ci, rhs
	shl	$22, rhs
	shr	$28, rhs	; rhs now has src reg 2
	mov	REGS(rhs), rhs	; rhs now has whatever was stored in the correspondent register
	mov	REGS(work0), work0 ;work0 now has whatever was stored in the correspondent register
	mul	work0, rhs
	mov	INSTR(op), rip
	
;;; Operations
	
add:	add	REGS(src), rhs
	mov	rhs, REGS(dst)
	add	$1, wpc
	jmp 	fetch
adc:
	
sub:	mov	REGS(src), work0
	sub	rhs, work0
	mov	work0, REGS(dst)
	add	$1, wpc
	jmp 	fetch

	
cmp:
eor:
orr:
and:
tst:
	
mul:	mul	REGS(src), rhs
	mov	rhs, REGS(dst)
	add	$1, wpc
	jmp	fetch

	
mla:	add	REGS(src), rhs
	mov	rhs, REGS(dst)
	add	$1, wpc
	jmp 	fetch
	
div:
mov:	
mvn:
swi:
ldm:
stm:
ldr:
str:
ldu:
stu:
adr:
bf:
bb:
blf:
blb:

REGS:
	.data	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
INSTR:
	.data 	add,adc,sub,cmp,eor,orr,and,tst,mul,mla,div,mov,mvn,swi,ldm,stm,ldr,str,ldu,stu,adr,0,0,0,bf,bb,blf,blb
TYPE:
	.data	arith, arith, ls, branch
ADDR:
	.data 	imd, imd, imd, imd, rim, rsr, rpm
SHOP:
	.data	lsl, lsr, asr, ror
WARM:	 
