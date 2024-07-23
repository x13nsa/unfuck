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
#        `--~|         |   |	Makefile
#            |         |   |
objs = main.o error.o fprintf.o interpreter.o
exec = unfuck

all: $(exec)

$(exec): $(objs)
	ld	-o $(exec) $(objs)
%.o: %.s
	as	-o $@ $<
clean:
	rm	-f $(objs) $(exec)
