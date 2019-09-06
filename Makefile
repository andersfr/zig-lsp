.PHONY: clean

all: parser server

parser: parser.zig errors.zig zig/*
	zig build-exe --single-threaded --release-fast --library c parser.zig

server: server.zig errors.zig zig/*
	zig build-exe --single-threaded --release-fast --library c server.zig

clean:
	rm -rf parser server *.o zig-cache
