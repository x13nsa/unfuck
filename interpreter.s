#               ____
#             /____ `\
#            ||_  _`\ \		Brainfuck interpreter
#      .-.   `|O, O  ||		art by: TBH'99
#      | |    (/    -)\		coded by: x13nsa
#      | |    |`-'` |./		date: Jul 23 2015
#   __/  |    | _/  |
#  (___) \.  _.\__. `\___
#  (___)  )\/  \    _/   ~\.
#  (___) . \   `--  _      |
#   (__)-    ,/        (   |
#        `--~|         |   |	interpreter itself bonsoir
#            |         |   |
.section	.bss
	.memory:	.zero	90000

.section	.text
.globl		interpret

.include	"macros.inc"


.macro	SET_NEW_MEM_POS
	incl	%ebx
	movl	%ebx, -8(%rbp)
	movl	%ebx, %eax
	cltq
	leaq	.memory(%rip), %r15
	addq	%rax, %r15
.endm

interpret:
	pushq	%rbp
	movq	%rsp, %rbp
	# -*----------------------------- Stack distribution -----------*
	#   -4(%rbp) : number of tokens.		[int]		#
	#   -8(%rbp) : current token index.		[int]		#
	subq	$8, %rsp
	movl	%edi, -4(%rbp)
	movl	$0, -8(%rbp)
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# r15 will controlate the memory.
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	leaq	.memory(%rip), %r15

.int_eat:
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# making sure there exist more tokens
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	movl	-8(%rbp), %eax
	cmpl	-4(%rbp), %eax
	jge	.int_fini
	cltq
	movq	tokens_sz(%rip), %rbx
	mulq	%rbx
	leaq	tokens(%rip), %r14
	addq	%rax, %r14
	movq	0(%r14), %rax
	movl	$0, %r8d
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# what to do?
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	movzbl	(%rax), %eax
	cmpb	$'+', %al
	je	.int_inc
	cmpb	$'-', %al
	je	.int_dec
	cmpb	$'<', %al
	je	.int_prev
	cmpb	$'>', %al
	je	.int_next
	cmpb	$'.', %al
	je	.int_out
	cmpb	$',', %al
	je	.int_in
	cmpb	$'[', %al
	je	.int_loop_open
	cmpb	$']', %al
	je	.int_loop_close
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# the program will never get here but we will take care of
	# everything ;)
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	jmp	E_UNKNOWN
.int_inc:
	movl	16(%r14), %eax
	addb	%al, (%r15)
	jmp	.int_continue
.int_dec:
	movl	16(%r14), %eax
	subb	%al, (%r15)
	jmp	.int_continue
.int_prev:
	movl	16(%r14), %eax
	cltq
	subq	%rax, %r15
	jmp	.int_continue
.int_next:
	movl	16(%r14), %eax
	cltq
	addq	%rax, %r15
	jmp	.int_continue
.int_out:
	movl	16(%r14), %eax
	cmpl	%eax, %r8d
	je	.int_continue
	movq	$1, %rax
	movq	$1, %rdi
	movq	%r15, %rsi
	movq	$1, %rdx
	syscall
	incl	%r8d
	jmp	.int_out
.int_in:
	cmpl	16(%r14), %r8d
	je	.int_continue
	movq	$0, %rax
	movq	$1, %rdi
	movq	%r15, %rsi
	movq	$1, %rdx
	syscall
	incl	%r8d
	jmp	.int_in
.int_loop_open:
	movl	16(%r14), %eax
	cmpl	$-1, %eax
	je	E_UNMATCHED
	movb	(%r15), %bl
	cmpb	$0, %bl
	jne	.int_continue
	movl	%eax, -8(%rbp)
	jmp	.int_eat
.int_loop_close:
	movb	(%r15), %bl
	cmpb	$0, %bl
	je	.int_continue
	movl	16(%r14), %eax
	movl	%eax, -8(%rbp)
.int_continue:
	incl	-8(%rbp)
	jmp	.int_eat
.int_fini:
	leave
	ret
