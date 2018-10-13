SHELL=/bin/sh
AS=as
LD=ld
OBJS=signals.o strutil.o entry.o main.o handle_input.o builtins.o sayexec.o env.o
OUT=sysh

all:$(OBJS)
	@for OBJ in $(OBJS); do echo -e "\tLD $$OBJ"; done
	@$(LD) $(OBJS) -o $(OUT) && echo -e '\tOUT $(OUT)'

$(OBJS): %.o: %.S
	@echo -e '\tAS $<'
	@$(AS) $< -o $@
	
clean:
	rm $(OBJS)

.PHONY: all, clean
