objs = main.o memset.o
exec = unfuck

all: $(exec)

$(exec): $(objs)
	ld	-o $(exec) $(objs)
%.o: %.s
	as	-o $@ $<
clean:
	rm	-f $(objs) $(exec)
