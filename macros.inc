#               ____
#             /____ `\
#            ||_  _`\ \		Brainfuck interpreter
#      .-.   `|O, O  ||		art by: TBH'99
#      | |    (/    -)\		coded by: x13nsa
#      | |    |`-'` |./		date: Jul 23 2015
#   __/  |    | _/  |		
#  (___) \.  _.\__. `\___
#  (___)  )\/  \    _/   ~\.
#  (___) . \   `--  _      |
#   (__)-    ,/        (   |
#        `--~|         |   |	stuff
#            |         |   |
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
