#!/bin/bash
# To make executable command:
#   chmod +x debug.sh
#   sudo cp ./debug.sh /usr/bin/debug
# Once done, simply execute as:
# $ debug [source file]
aarch64-linux-gnu-as -g -o a.o $1
aarch64-linux-gnu-gcc -static -o a.elf a.o
qemu-aarch64 -g 8888 ./a.elf &
gdb-multiarch ./a.elf
# remove the temporary files after execution
rm -f a.o a.elf