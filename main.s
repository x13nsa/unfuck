.section	.rodata
	.max_num_tokens:	.quad	2048
	.max_num_loops:		.quad	1024
	.token_sz:		.quad	  20

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
	movl	$0, %eax
	cmpb	$'.', %dil
	je	.is_it_no
	cmpb	$',', %dil
	je	.is_it_no
	cmpb	$'[', %dil
	je	.is_it_no
	cmpb	$']', %dil
	je	.is_it_no
	cmpb	$'<', %dil
	je	.is_it_no
	cmpb	$'>', %dil
	je	.is_it_no
	cmpb	$'+', %dil
	je	.is_it_no
	cmpb	$'-', %dil
	je	.is_it_no
	movl	$1, %eax
.is_it_no:
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
how_many:


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
	movl	$0, -28(%rbp)						#
	movq	$4, -36(%rbp)						#
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
	jnz	.lex_non_code
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# Checking aint overflow
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	movq	-36(%rbp), %rax
	cmpq	%rax, .max_num_tokens(%rip)
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
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# [ and ] are special tokens since they must not to be accumulated
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	cmpb	$'[', %dil
	je	.lex_opening
	cmpb	$']', %dil
	je	.lex_closing

	jmp	.lex_continue

.lex_opening:
.lex_closing:
	EXIT_	$96

.lex_non_code:
	cmpb	$'\n', %dil
	je	.lex_new_line
	incl	-28(%rbp)
	jmp	.lex_continue

.lex_new_line:
	incl	-24(%rbp)
	movl	$0, -28(%rbp)

.lex_continue:
	incq	%r15
	jmp	.lexer_pick

.lexer_end:
	EXIT_	$96
