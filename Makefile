
all:
	make -C source/ROM $@
	
clean:
	make -C source/ROM $@
	rm -rf bin

