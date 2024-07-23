.section	.rodata
	.usage_msg:		.string	"\tusage: unfuck [file]\n"
	.usage_len:		.long	22

	.file_issue_msg:	.string	"\terror: file issue...\n"
	.file_issue_len:	.long	22

	.mem_issue_msg:		.string	"\terror: memory issue...\n"
	.mem_issue_len:		.long	24

	.token_overflow_msg:	.string "\terror: token overflow\n"
	.token_overflow_len:	.long	23

	.loop_overflow_msg:	.string "\terror: loop overflow\n"
	.loop_overflow_len:	.long	22

	.unmatched_pair_msg:	.string "\terror: unmatched pair\n"
	.unmatched_pair_len:	.long	23

	.err_fmt:		.string "\t(%d:%d): %c causes the error.\n"

.section	.text
.include	"macros.inc"

.globl		E_USAGE
.globl		E_FILE_ISSUES
.globl		E_MEM_ISSUES
.globl		E_TOKEN_OVERFLOW
.globl		E_LOOP_OVERFLOW
.globl		E_UNMATCHED

E_USAGE:
	PRINT_	$2, .usage_len(%rip), .usage_msg(%rip)
	EXIT_	$0

E_FILE_ISSUES:
	PRINT_	$2, .file_issue_len(%rip), .file_issue_msg(%rip)
	EXIT_	$1

E_MEM_ISSUES:
	PRINT_	$2, .mem_issue_len(%rip), .mem_issue_msg(%rip)
	EXIT_	$2

E_TOKEN_OVERFLOW:
	PRINT_	$2, .token_overflow_len(%rip), .token_overflow_msg(%rip)
	EXIT_	$3
E_LOOP_OVERFLOW:
	PRINT_	$2, .loop_overflow_len(%rip), .loop_overflow_msg(%rip)
	EXIT_	$4
E_UNMATCHED:
	PRINT_	$2, .unmatched_pair_len(%rip), .unmatched_pair_msg(%rip)
	call	.formated_error
	EXIT_	$5

.formated_error:
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
	# r14 saves a pointer to the token
	# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'
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
	movl	$2, %edi
	leaq	.err_fmt(%rip), %rsi
	call	fprintf_
	popq	%rax
	popq	%rax
	popq	%rax
	ret
