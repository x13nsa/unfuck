.section	.rodata
	.usage_m:	.string	"\tusage: unfuck [mode] [file]\n"
	.usage_l:	.long	29

	.bad_file_m:	.string "\terror: bad file\n"
	.bad_file_l:	.long	17

	.bad_alloc_m:	.string "\terror: bad alloc\n"
	.bad_alloc_l:	.long	18

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
	movl	\a, %edi
	movl	$60, %eax
	syscall
.endm

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
	movl	%eax, -4(%rbp)
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

	EXIT_	$0

.display_usage:
	SHOW_MSG_	.usage_m(%rip), .usage_l(%rip)
	EXIT_		$0
.display_bad_file:
	SHOW_MSG_	.bad_file_m(%rip), .bad_file_l(%rip)
	EXIT_		$1
.display_bad_alloc:
	SHOW_MSG_	.bad_alloc_m(%rip), .bad_alloc_l(%rip)
	EXIT_		$2
