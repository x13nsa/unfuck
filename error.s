.section	.rodata
	.usage_msg:		.string	"\tusage: unfuck [file]\n"
	.usage_len:		.long	22

	.file_issue_msg:	.string	"\terror: file issue...\n"
	.file_issue_len:	.long	22

	.mem_issue_msg:		.string	"\terror: memory issue...\n"
	.mem_issue_len:		.long	24

	.token_overflow_msg:	.string "\terror: token overflow\n"
	.token_overflow_len:	.long	23

.section	.text
.include	"macros.inc"

.globl		E_USAGE
.globl		E_FILE_ISSUES
.globl		E_MEM_ISSUES
.globl		E_TOKEN_OVERFLOW

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
