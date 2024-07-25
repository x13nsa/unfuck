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
