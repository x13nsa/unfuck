.section	.text
.globl		memset_

# arguments:	mem (rdi) ; value (sil) ; n (rdx)
# return:	1 on success 0 otherwise
# regs:		rdi, rsi, rdx, rcx
memset_:
	cmpq	$0, %rdi
	je	.memset_bad
	movq	$0, %rcx
.memset_loop:
	cmpq	%rcx, %rdx
	je	.memset_ok
	movb	%sil, (%rdi)
	incq	%rcx
	incq	%rdi
	jmp	.memset_loop
.memset_bad:
	movq	$0, %rax
	jmp	.memset_end
.memset_ok:
	movq	$1, %rax
.memset_end:
	ret
