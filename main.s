# TODO: unmap -12(%rbp)

.section	.rodata
	.usage_m:	.string	"\tusage: unfuck [mode] [file]\n"
	.usage_l:	.long	29

	.bad_file_m:	.string "\terror: bad file\n"
	.bad_file_l:	.long	17

	.bad_alloc_m:	.string "\terror: bad alloc\n"
	.bad_alloc_l:	.long	18

	.bad_tokovrf_m:	.string	"\terror: token overflow; inc cap\n"
	.bad_tokovrf_l:	.long	32

	.token_size:	.quad	20
	.max_tok_num:	.long	2048
	.max_jmp_num:	.long	256

.section	.bss
	.type		.tokens, @object
	.size		.tokens, 20 * 2048
	.tokens:	.zero	 20 * 2048

	.type		.jumps, @object
	.size		.jumps, 4 * 256
	.jumps:		.zero	4 * 256

.section	.text
.globl		_start

.macro	SHOW_MSG_, a, b
	leaq	\a, %rsi
	movl	\b, %edx
	movl	$1, %edi
	movl	$1, %eax
	syscall
.endm

.macro	EXIT_, a
	movq	\a, %rdi
	movq	$60, %rax
	syscall
.endm

#  ____________
# < but is it? >
#  ------------
#         \   ^__^
#          \  (oo)\_______
#             (__)\       )\/\
#                 ||----w |
#                 ||     ||
is_token_:
	movl	$1, %eax
	cmpb	$'+', %dil
	je	.is_token_end
	cmpb	$'-', %dil
	je	.is_token_end
	cmpb	$'<', %dil
	je	.is_token_end
	cmpb	$'>', %dil
	je	.is_token_end
	cmpb	$'[', %dil
	je	.is_token_end
	cmpb	$']', %dil
	je	.is_token_end
	cmpb	$'.', %dil
	je	.is_token_end
	cmpb	$',', %dil
	je	.is_token_end
	movl	$0, %eax
.is_token_end:
	ret


#  _________________________________________
# < how many times does it appear in a row? >
#  -----------------------------------------
#         \   ^__^
#          \  (oo)\_______
#             (__)\       )\/\
#                 ||----w |
#                 ||     ||
in_row_:
	movq	$1, %rcx
	movzbl	(%rdi), %esi
	incq	%rdi
.in_row_continue:
	movzbl	(%rdi), %eax
	cmpl	%eax, %esi
	jne	.in_row_no_longer
	incq	%rdi
	incq	%rcx
	jmp	.in_row_continue
.in_row_no_longer:
	movq	%rcx, %rax
	ret

_start:
	popq	%rax
	cmpq	$3, %rax
	jne	.display_usage
	popq	%rax
	popq	%rax
	popq	%rdi
	movzbl	(%rax), %eax
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$32, %rsp
	# Stack distribution
	# -4(%rbp): mode to be used.
	# -12(%rbp): ptr to file's content.
	# -16(%rbp): current token's index.
	# -20(%rbp): number line.
	# -24(%rbp): line offset.
	movl	%eax, -4(%rbp)
	movl	$0, -16(%rbp)
	movl	$1, -20(%rbp)
	movl	$0, -24(%rbp)
	# Checking file is accessable
	# access(rdi, F_OK)
	movq	$21, %rax
	movl	$0, %esi
	syscall
	cmpl	$0, %eax
	jne	.display_bad_file
	# Opening the file and getting the fd.
	# open(rdi, O_RDONLY, 0);
	movq	$2, %rax
	movl	$0, %esi
	movl	$0, %edx
	syscall
	# Getting file size.
	# lseek(edi, 0, SEEK_END) && lseek(edi, 0, SEEK_SET)
	# size = r15
	movl	%eax, %edi
	movq	$0, %rsi
	movl	$2, %edx
	movl	$8, %eax
	syscall
	movq	%rax, %r15
	movl	$0, %edx
	movl	$8, %eax
	syscall
	movl	%edi, %ebx
	# Making space for the file's content.
	# mmap(NULL, r15, MAP_READ | MAP_WRITE, MAP_ANONYMOUS | MAP_PRIVATE, -1, 0)
	movq	$0, %rdi
	incq	%r15
	movq	%r15, %rsi
	movl	$3, %edx
	movl	$34, %r10d
	movl	$-1, %r8d
	movq	$0, %r9
	movq	$9, %rax
	syscall
	cmpq	$-1, %rax
	je	.display_bad_alloc
	movq	%rax, -12(%rbp)
	movq	%rax, %rdi
	movb	$0, %sil
	movq	%r15, %rdx
	call	memset_
	# Reading file's content.
	# open(fd, buf, r15)
	movl	%ebx, %edi
	movq	-12(%rbp), %rsi
	movq	%r15, %rdx
	movq	$0, %rax
	syscall
	# closing file
	movq	$3, %rax
	syscall
	# r15 will hold a pointer to the bf code.
	movq	-12(%rbp), %r15
.lexer_loop:
	movzbl	(%r15), %eax
	testl	%eax, %eax
	jz	.lexer_fini
	movl	%eax, %edi
	movl	-16(%rbp), %eax
	# making sure there is capacity enough
	cmpl	%eax, .max_tok_num(%rip)
	je	.display_token_overflow
	# checking the current byte is a token.
	call	is_token_
	testl	%eax, %eax
	jz	.lexer_non_token
	# getting this token (r14).
	movl	-16(%rbp), %eax
	cltq
	movq	.token_size(%rip), %rbx
	mulq	%rbx
	leaq	.tokens(%rip), %rbx
	addq	%rax, %rbx
	movq	%rbx, %r14
	# struct token {
	# 	char	*context;	 0(r14)
	#	int	nline;		 8(r14)
	#	int	offset;		12(r14)
	#	int	mark;		16(r14)
	# }
	movq	%r15, (%r14)
	movl	-20(%rbp), %eax
	movl	%eax, 8(%r14)
	movl	-24(%rbp), %eax
	movl	%eax, 12(%r14)
	# [ and ] tokens cannot be accumulated.
	movzbl	(%r15), %edi
	cmpb	$'[', %dil
	je	.lexer_opening
	cmpb	$']', %dil
	je	.lexer_closing
	movq	%r15, %rdi
	call	in_row_
	movl	%eax, 16(%r14)
	# updating new position.
	decq	%rax
	addq	%rax, %r15

	# HERE

	jmp	.lexer_inc_index

.lexer_opening:
	EXIT_	$69
.lexer_closing:
	EXIT_	$70

.lexer_inc_index:
	incl	-16(%rbp)
	jmp	.lexer_continue

.lexer_non_token:
	cmpb	$'\n', %dil
	jne	.lexer_continue
	incl	-20(%rbp)
	movl	$0, -24(%rbp)
.lexer_continue:
	incq	%r15
	jmp	.lexer_loop


.lexer_fini:
	EXIT_	$69

.display_usage:
	SHOW_MSG_	.usage_m(%rip), .usage_l(%rip)
	EXIT_		$0
.display_bad_file:
	SHOW_MSG_	.bad_file_m(%rip), .bad_file_l(%rip)
	EXIT_		$1
.display_bad_alloc:
	SHOW_MSG_	.bad_alloc_m(%rip), .bad_alloc_l(%rip)
	EXIT_		$2
.display_token_overflow:
	SHOW_MSG_	.bad_tokovrf_m(%rip), .bad_tokovrf_l(%rip)
	EXIT_		$2
