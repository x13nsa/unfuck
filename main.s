.section	.rodata
	.max_num_tokens:	.quad	2048
	.max_num_loops:		.quad	1024
	.token_sz:		.quad	  20

	.token_info:		.string "(%d:%d):\t\t%c\t\t[%d]\n"

.section	.bss
	# struct Token {
	# 	char	*context;	 0(reg)
	#	int	numline;	 8(reg)
	#	int 	offset;		12(reg)
	#	int	mark;		16(reg)
	# } : this is what a token looks like and
	#     it is 20 bytes long.
	.tokens:	.zero	2048 * 20
	.loopids:	.zero	1024 *  4

.section	.text
.globl		_start

.include	"macros.inc"

#  _____________
# < is it code? >
#  -------------
#         \   ^__^
#          \  (@@)\_______
#             (__)\       )\/\
#                 ||----w |
#                 ||     ||
is_it_code:
	movl	$1, %eax
	cmpb	$'.', %dil
	je	.is_it_end
	cmpb	$',', %dil
	je	.is_it_end
	cmpb	$'[', %dil
	je	.is_it_end
	cmpb	$']', %dil
	je	.is_it_end
	cmpb	$'<', %dil
	je	.is_it_end
	cmpb	$'>', %dil
	je	.is_it_end
	cmpb	$'+', %dil
	je	.is_it_end
	cmpb	$'-', %dil
	je	.is_it_end
	movl	$0, %eax
.is_it_end:
	ret

#  ___________________________________
# < how big is your group of friends? >
#  -----------------------------------
#         \   ^__^
#          \  (@@)\_______
#             (__)\       )\/\
#                 ||----w |
#                 ||     ||
# args: rdi (context); rsi (number line ptr); rdx (line offset ptr)
# regs: rdi, rsi, rdx, rax, rbx, r8, r9
how_many_:
	movq	%rdi, %r8
	movl	$1, %r9d
	movzbl	(%r8), %ebx
	incq	%r8
.how_many_loop:
	incl	(%rdx)
	movzbl	(%r8), %edi
	call	is_it_code
	testl	%eax, %eax
	jz	.how_many_non_token
	cmpl	%edi, %ebx
	jne	.how_many_fini
	incl	%r9d
	jmp	.how_many_continue
.how_many_non_token:
	testl	%edi, %edi
	jz	.how_many_fini
	cmpb	$'\n', %dil
	jne	.how_many_continue
	incl	(%rsi)
	movl	$0, (%rdx)
.how_many_continue:
	incq	%r8
	jmp	.how_many_loop
.how_many_fini:
	movl	%r9d, %eax
	decq	%r8
	movq	%r8, %r15
	ret

_start:
	popq	%rax
	cmpq	$2, %rax
	jne	E_USAGE
	popq	%rax
	movq	(%rsp), %rax
	pushq	%rbp
	movq	%rsp, %rbp
	# -*----------------------------- Stack distribution -----------*
	#   -4(%rbp) : fd (input file).		[int]			#
	#  -12(%rbp) : input file size.		[long]			#
	#  -20(%rbp) : input file's content.	[ptr]			#
	#  -24(%rbp) : number line.		[int]			#
	#  -28(%rbp) : line offset.		[int]			#
	#  -36(%rbp) : current token indx.	[long]			#
	#  -44(%rbp) : current loop indx.	[long]			#
	subq	$64, %rsp						#
	movl	$1, -24(%rbp)						#
	movl	$1, -28(%rbp)						#
	movq	$0, -36(%rbp)						#
	movq	$0, -44(%rbp)						#
	# -*----------------------------- Making sure file is OK! ------*
	movq	%rax, %rdi						#
	movl	$0, %esi						#
	movq	$21, %rax						#
	syscall								#
	testl	%eax, %eax						#
	jnz	E_FILE_ISSUES						#
	# -*----------------------------- Opening file -----------------*
	xorq	%rsi, %rsi						#
	movq	$2, %rax						#
	syscall								#
	movl	%eax, -4(%rbp)						#
	# -*----------------------------- Getting file size ------------*
	movl	-4(%rbp), %edi						#
	xorl	%esi, %esi						#
	movl	$2, %edx						#
	movq	$8, %rax						#
	syscall								#
	movq	%rax, -12(%rbp)						#
	movl	-4(%rbp), %edi						#
	xorl	%esi, %esi						#
	movl	$0, %edx						#
	movq	$8, %rax						#
	syscall								#
	# -*----------------------------- Allocating space -------------*
	movq	$0, %rdi						#
	movq	-12(%rbp), %rsi						#
	incq	%rsi							#
	movl	$3, %edx						#
	movq	$34, %r10						#
	movq	$-1, %r8						#
	movq	$0, %r9							#
	movq	$9, %rax						#
	syscall								#
	cmpq	$-1, %rax						#
	je	E_MEM_ISSUES						#
	movq	%rax, -20(%rbp)						#
	# -*----------------------------- Reading file -----------------*
	movl	-4(%rbp), %edi						#
	movq	-20(%rbp), %rsi						#
	movq	-12(%rbp), %rdx						#
	movq	$0, %rax						#
	syscall								#
	# -*----------------------------- Setting \0 byte --------------*
	movq	-20(%rbp), %rax						#
	addq	-12(%rbp), %rax						#
	movb	$0, (%rax)						#
	# -*----------------------------- Closing file -----------------*
	movl	-4(%rbp), %edi						#
	movq	$3, %rax						#
	syscall								#
	# -*----------------------------- Lexing -----------------------*
	movq	-20(%rbp), %r15						#
.lexer_pick:
	movzbl	(%r15), %edi
	testl	%edi, %edi
	jz	.lexer_end
	call	is_it_code
	testl	%eax, %eax
	jz	.lex_non_code
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# Checking aint overflow
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	movq	-36(%rbp), %rax
	cmpq	.max_num_tokens(%rip), %rax
	je	E_TOKEN_OVERFLOW
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# Current token will be stored into r14
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	movq	.token_sz(%rip), %rbx
	mulq	%rbx
	leaq	.tokens(%rip), %r14
	addq	%rax, %r14
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# Setting values ya know
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	movq	%r15, 0(%r14)
	movl	-24(%rbp), %eax
	movl	%eax, 8(%r14)
	movl	-28(%rbp), %eax
	movl	%eax, 12(%r14)
	incl	-28(%rbp)
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# [ and ] are special tokens since they must not to be accumulated
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	cmpb	$'[', %dil
	je	.lex_opening
	cmpb	$']', %dil
	je	.lex_closing
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# Number of times the token appears in a row
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	movq	%r15, %rdi
	leaq	-24(%rbp), %rsi
	leaq	-28(%rbp), %rdx
	call	how_many_
	movl	%eax, 16(%r14)
	jmp	.lex_got_token

.lex_opening:
	movq	-44(%rbp), %rcx
	cmpq	.max_num_loops(%rip), %rcx
	je	E_LOOP_OVERFLOW
	movl	$-1, 16(%r14)
	movl	-36(%rbp), %ebx
	leaq	.loopids(%rip), %rax
	leaq	(%rax, %rcx, 4), %rax
	movl	%ebx, (%rax)
	incq	-44(%rbp)
	jmp	.lex_got_token

.lex_closing:
	movq	-44(%rbp), %rcx
	cmpq	$0, %rcx
	je	E_UNMATCHED
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# getting the index of the last [	(rax)
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	decq	%rcx	
	leaq	.loopids(%rip), %rax
	movl	(%rax, %rcx, 4), %eax
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# Setting the jump to ] token.
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	movl	%eax, 16(%r14)
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# getting the last [ token	(rbx)
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	cltq
	movq	.token_sz(%rip), %rbx
	mulq	%rbx
	leaq	.tokens(%rip), %rbx
	addq	%rax, %rbx
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# linking both pairs [ -> ] and [ <- ]
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	movq	-36(%rbp), %rax
	movl	%eax, 16(%rbx)
	decq	-44(%rbp)
	jmp	.lex_got_token

.lex_non_code:
	incl	-28(%rbp)
	cmpb	$'\n', %dil
	jne	.lex_continue

.lex_new_line:
	incl	-24(%rbp)
	movl	$1, -28(%rbp)
	jmp	.lex_continue

.lex_got_token:
	incq	-36(%rbp)

.lex_continue:
	incq	%r15
	jmp	.lexer_pick

.lexer_end:
	movq	$0, %r8
.aaa:
	cmpq	-36(%rbp), %r8
	je	.bbb

	movq	%r8, %rax
	movq	.token_sz(%rip), %rbx
	mulq	%rbx
	leaq	.tokens(%rip), %r14
	addq	%rax, %r14

	movl	16(%r14), %eax
	cltq
	pushq	%rax
	movq	0(%r14), %rax
	movzbl	(%rax), %eax
	cltq
	pushq	%rax
	movl	12(%r14), %eax
	cltq
	pushq	%rax
	movl	8(%r14), %eax
	cltq
	pushq	%rax
	movl	$1, %edi
	leaq	.token_info(%rip), %rsi
	call	fprintf_
	popq	%rax
	popq	%rax
	popq	%rax
	popq	%rax

	incq	%r8
	jmp	.aaa

.bbb:
	EXIT_	$96
