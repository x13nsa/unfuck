.section	.rodata
	.usage_msg:		.string	"\tusage: unfuck [file]\n"
	.usage_len:		.long	22

	.file_issue_msg:	.string	"\terror: file issue...\n"
	.file_issue_len:	.long	22

	.mem_issue_msg:		.string	"\terror: memory issue...\n"
	.mem_issue_len:		.long	24

.section	.text
.globl		_start

.macro	PRINT_, a, b, c
	movl	\a, %edi
	movl	\b, %edx
	leaq	\c, %rsi
	movl	$1, %eax
	syscall
.endm

.macro	EXIT_, a
	movl	\a, %edi
	movl	$60, %eax
	syscall
.endm

_start:
	popq	%rax	
	cmpq	$2, %rax
	jne	.print_usage
	popq	%rax
	movq	(%rsp), %rax
	pushq	%rbp
	movq	%rsp, %rbp
	# stack distribution
	#  -8(%rbp): filename			(str ptr).
	# -12(%rbp): fd (input file)		(int).
	# -20(%rbp): input file size		(long).
	# -28(%rbp): file's content ptr		(mem ptr).
	subq	$32, %rsp
	movq	%rax, -8(%rbp)
	# -*-
	movq	-8(%rbp), %rdi
	movl	$0, %esi
	movq	$21, %rax
	syscall
	testl	%eax, %eax
	jnz	.file_issues	
	# -*----------------------------- Making sure file is OK! ------*
	xorq	%rsi, %rsi						#
	movq	$2, %rax						#
	syscall								#
	movl	%eax, -12(%rbp)						#
	# -*----------------------------- Getting file size ------------*
	movl	-12(%rbp), %edi						#
	xorl	%esi, %esi						#
	movl	$2, %edx						#
	movq	$8, %rax						#
	syscall								#
	movq	%rax, -20(%rbp)						#
	movl	-12(%rbp), %edi						#
	xorl	%esi, %esi						#
	movl	$0, %edx						#
	movq	$8, %rax						#
	syscall								#
	# -*----------------------------- Allocating space -------------*
	movq	$0, %rdi						#
	movq	-20(%rbp), %rsi						#
	movl	$3, %edx						#
	movq	$34, %r10						#
	movq	$-1, %r8						#
	movq	$0, %r9							#
	movq	$9, %rax						#
	syscall								#
	cmpq	$-1, %rax						#
	je	.mem_issues						#
	movq	%rax, -28(%rbp)						#
	# -*----------------------------- Reading file -----------------*
	movl	-12(%rbp), %edi						#
	movq	-28(%rbp), %rsi						#
	movq	-20(%rbp), %rdx						#
	movq	$0, %rax						#
	syscall								#

	movq	-28(%rbp), %rsi
	movq	-20(%rbp), %rdx
	movq	$1, %rdi
	movq	$1, %rax
	syscall

	EXIT_	$0

.print_usage:
	PRINT_	$2, .usage_len(%rip), .usage_msg(%rip)
	EXIT_	$0
.file_issues:
	EXIT_	%edi
	PRINT_	$2, .file_issue_len(%rip), .file_issue_msg(%rip)
	EXIT_	$1
.mem_issues:
	PRINT_	$2, .mem_issue_len(%rip), .mem_issue_msg(%rip)
	EXIT_	$1
