all:
	dmd -of=zippo source/main.d source/zinterface.d source/zutility.d && rm *.o
clean:
	rm zippo
