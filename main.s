.section	.text
.globl		_start


_start:
	movq	$60, %rax
	movq	$60, %rdi
	syscall
