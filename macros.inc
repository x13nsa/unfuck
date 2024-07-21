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
