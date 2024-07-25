#               ____
#             /____ `\
#            ||_  _`\ \
#      .-.   `|O, O  ||		art by:		TBH'99
#      | |    (/    -)\		coded by:	x13nsa
#      | |    |`-'` |./		last update:	Jul 23 2015
#   __/  |    | _/  |
#  (___) \.  _.\__. `\___
#  (___)  )\/  \    _/   ~\.
#  (___) . \   `--  _      |
#   (__)-    ,/        (   |
#        `--~|         |   |	Tabs: 8
#            |         |   |
# ffprintf for x86
# this a pretty simple implementation of the `fprintf' function found
# in the C programming language, it goes something like fprintf_(fd, fmt, ...)
# but in this case the extra arguments are pushed into the stack in the
# inverse order they will be used, for example if the programmer wants to do
# something like (c-like) fprintf(stderr, "err: %s is unknown. Line: %d\n", str, int);
# now they would have to do it this way:
#	movl	$2, %esi		(stderr).
#	leaq	.fmt(%rip), %rdi	(format wherever it is).
#	pushq	%rax			(rax contains the integer value) (EXAMPLE)
#	pushq	%rsi			(rsi contains the string value) (EXAMPLE)
#	call	fprintf_
# as you can see the order of the parameters is different.
# It is up to the programmer to free the element pushed into the stack once
# the function is completed, since the _fprintf does not pop anything, it only
# takes whatever follows; the programmer either can:
#
#	addq	$x, %rsp	or	popq	%reg
#                `                      ~~~~~~~~~~~~
#          8 times the number		do this for each element
#          of arguments used.		pushed.
#
# The stack once fprintf_ is reached will look something like:
#	+----------------+
#	+    0xfaabbd    + -> your old rbp
#	+~~~~~~~~~~~~~~~~+
#	+		 +
#	+		 + -> stuff from your current function.
#	+		 +
#	+~~~~~~~~~~~~~~~~+
#	+   argument 1   +	pushed
#	+~~~~~~~~~~~~~~~~+
#	+   argument 2   +	pushed
#	+~~~~~~~~~~~~~~~~+
#	+   argument 3   +	pushed
#	+~~~~~~~~~~~~~~~~+
#	+   argument 4   +	pushed
#	+~~~~~~~~~~~~~~~~+
#	+    0xf4589a    + -> address memoery to go back.
#	+~~~~~~~~~~~~~~~~+
#	+    0xfaabbd    + -> your new rbp (from here arguments are gotten): 16(%rbp, k, 8)
#	+----------------+							      ~ index of argument.
#	+		 +
#	+		 + -> fprintf_ stuff.
#	+----------------+
.section	.bss
	.buffer:	.zero	2048
	.numbuf:	.zero	32

.section	.rodata
	.err_unknw_fmt_msg:	.string "fprintf_: unknown fmt.\n"
	.err_unknw_fmt_len:	.long	22

	.err_overflow_msg:	.string "fprintf_: fmt overflow.\n"
	.err_overflow_len:	.long	23

	.tester:		.string "neg: %d %d %d %d\n"

	.buffer_cap:	.quad	2048
	.numbuf_cap:	.quad	32

.section	.text
.globl		fprintf_

.macro	EXIT_, a
	movq	\a, %rdi
	movq	$60, %rax
	syscall
.endm

.macro	ERROR_, a, b
	leaq	\a, %rsi
	movl	\b, %edx
	movl	$1, %eax
	movl	$2, %edi
	syscall
.endm

.macro	CHECK_FOR_SPACE
	movq	-36(%rbp), %rcx
	cmpq	%rcx, .buffer_cap(%rip)
	je	.fprintf_err_overflow
.endm

.macro	BYTE_WRITTEN
	incq	-28(%rbp)
	incq	-36(%rbp)
.endm

# arguments:	fd (edi) ; fmt (rsi) ; arguments (pushed into the stack)
# return:	number of bytes written.
# regs:		rax, rdi, rsi, rcx, rbx
fprintf_:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$36, %rsp
	# stack distribution.
	# -8(%rbp):	index of the current argument.
	# -12(%rbp):	write to (fd).
	# -20(%rbp):	format.
	# -28(%rbp):	pointer to the buffer.
	# -36(%rbp):	number of bytes written so far (into the buffer).
	movq	$0, -8(%rbp)
	movq	$0, -36(%rbp)
	movl	%edi, -12(%rbp)
	movq	%rsi, -20(%rbp)
	leaq	.buffer(%rip), %rax
	movq	%rax, -28(%rbp)
.fprintf_loop:
	movq	-20(%rbp), %rax
	movzbl	(%rax), %edi
	testl	%edi, %edi
	jz	.fprintf_goodbye
	# cheking for space.
	CHECK_FOR_SPACE
	# is it format?
	cmpb	$'%', %dil
	je	.fprintf_fmt_found
	# storing current non-formated-characer into the buffer.
	movq	-28(%rbp), %rax
	movb	%dil, (%rax)
	# go for the next character in the fmt.
	# prepare the next byte in the buffer.
	# increase the number of bytes stored into the buffer.
	incq	-20(%rbp)
	BYTE_WRITTEN
	jmp	.fprintf_loop
.fprintf_fmt_found:
	# getting the format.
	# "this is the fmt (%c).\n"
	#                    ` now here not at %.
	incq	-20(%rbp)
	movzbl	1(%rax), %eax
	# may this is not a format.
	cmpb	$'%', %al
	je	.fprintf_fmt_skip
	# getting the value for this format; stored into rbx.
	movq	-8(%rbp), %rbx
	movq	16(%rbp, %rbx, 8), %rbx
	incq	-8(%rbp)
	# -*-
	cmpb	$'d', %al
	je	.fprintf_fmt_number
	cmpb	$'s', %al
	je	.fprintf_fmt_string
	cmpb	$'c', %al
	je	.fprintf_fmt_character
	jmp	.fprintf_err_unknown_fmt

.fprintf_fmt_number:
	# rsi will act as a buffer to save
	# the number, it will be saved in the
	# reverse orden, for example:
	# +-----------------------------------------------+
	# +                                   <----- $  * + numbuf
	# +------------------------------------------|--v-+
	#                          start from here --+  nullbyte
	# therefore 452 would look like:
	# +-----------------------------------------------+
	# +                                !  2  5  4  *  + numbuf
	# +--------------------------------/--v-----------+
	#                       not used...  rsi is here!!
	leaq	.numbuf(%rip), %rsi
	addq	.numbuf_cap(%rip), %rsi
	decq	%rsi
	# -*-
	movq	%rbx, %rax
	cmpq	$0, %rax
	jg	.fprintf_fmt_num_get
	cmpq	$0, %rax
	jl	.fprintf_fmt_num_neg
	movq	-28(%rbp), %rax
	movb	$'0', (%rax)
	BYTE_WRITTEN
	jmp	.fprintf_fmt_done
.fprintf_fmt_num_neg:
	movq	-28(%rbp), %rbx
	movb	$'-', (%rbx)
	negq	%rax
	BYTE_WRITTEN
.fprintf_fmt_num_get:
	testq	%rax, %rax
	jz	.fprintf_fmt_num_end
	movq	$10, %rbx
	cdq
	divq	%rbx
	addq	$'0', %rdx
	movb	%dl, (%rsi)
	decq	%rsi
	jmp	.fprintf_fmt_num_get
.fprintf_fmt_num_end:
	incq	%rsi
	movq	%rsi, %rbx

.fprintf_fmt_string:
	movzbl	(%rbx), %edi
	testl	%edi, %edi
	jz	.fprintf_fmt_done
	CHECK_FOR_SPACE
	# storing character from the string.
	movq	-28(%rbp), %rax
	movb	%dil, (%rax)
	# keep going my bby.
	incq	-28(%rbp)
	incq	-36(%rbp)
	incq	%rbx
	jmp	.fprintf_fmt_string

.fprintf_fmt_character:
	movq	-28(%rbp), %rax
	movb	%bl, (%rax)
	incq	-28(%rbp)
	incq	-36(%rbp)
	jmp	.fprintf_fmt_done

.fprintf_fmt_skip:
	movq	-28(%rbp), %rax
	movb	$'%', (%rax)
	incq	-28(%rbp)
	incq	-36(%rbp)
	jmp	.fprintf_fmt_done

.fprintf_fmt_done:
	incq	-20(%rbp)
	jmp	.fprintf_loop

.fprintf_goodbye:
	leaq	.buffer(%rip), %rsi
	movq	-36(%rbp), %rdx
	movq	$1, %rax
	movl	-12(%rbp), %edi
	syscall
	movq	-36(%rbp), %rax
	leave
	ret

#  ___________________
# < damnnnnnnn errors >
#  -------------------
#         \   ^__^
#          \  (oo)\_______
#             (__)\       )\/\
#                 ||----w |
#                 ||     ||
.fprintf_err_unknown_fmt:
	ERROR_	.err_unknw_fmt_msg(%rip), .err_unknw_fmt_len(%rip)
	EXIT_	$1
.fprintf_err_overflow:
	ERROR_	.err_overflow_msg(%rip), .err_overflow_len(%rip)
	EXIT_	$1
