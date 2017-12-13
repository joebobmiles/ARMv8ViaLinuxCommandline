# Running ARMv8 via Linux Command Line

## About this Repo

This repo contains information regarding running ARMv8 code on a non-ARM machine via Linux command line as well as some scripts and tools for automating much of the process of setup, compilation and linking.

## Compiling ARMv8

### Installing a Cross Compiler

Machines running ARMv8 architectures have the priviledge of simply running `as` on the ARMv8 source file and then `gcc` on the corresponding object file to assemble and link the ARMv8 code into an executable. However, for non-ARMv8 machines, we can't simply run those commands, as they will attempt to compile the ARMv8 assembly as x86_64 assembly. To compile ARMv8 as ARMv8 on a non-ARMv8 machine, we need a cross compiler. Thankfully, the GNU project has a suite of cross compiler tools that we can use for ARMv8. To install on Ubuntu (or other Debian based systems), run:

```shell
$ sudo apt install binutils-aarch64-linux-gnu
```

This will install all the necissary applications for cross compiling ARMv8 code. These packages should also available on distros that use other package managers, such as Arch and Fedora (and their derivatives).

### Compiling ARMv8

Compiling assembly requires two steps: assembling and linking. Assembling reduces the assembly source to non-executable bytecode. That bytecode is then _linked_ with any external binary dependencies via a linker and turned into an executable binary. On an ARMv8 machine, we can simply run `as` on our source file to assemble it, then `ld` on the resultant object file to link it and produce a working executable. However, using `ld` is usually avoided if you want to include C functions into your assembly programs. To link ARMv8 programs that contain C function calls, you should use `gcc` instead.

Again, the above commands only run on ARMv8 machines. For us (who are supposedly running x86/x86_64 machines), we need to run the following commands that were installed with the `binutils-aarch64-linux-gnu` package to assemble and then link the ARMv8 code:

```shell
$ aarch64-linux-gnu-as -o a.o [the name of your source file]
$ aarch64-linux-gnu-gcc -static -o [the name of the executable] a.o
```

Both these commands are long, but hopefully you noticed `as` and `gcc`. After running them, there would be two new files, an object file `a.o` and an executable with some arbitrary name. If you run the `file` command on your executable, you should see output like this:

```shell
ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, for GNU/Linux 3.7.0
```

However, if you go to run the executable, your computer will complain. That is because you compiled your ARMv8 source code into an ARMv8 (aarch64) binary format. Which means that you code can only run on an ARMv8 architecture. Enter QEMU...

## QEMU to Emulate ARM

### Installing QEMU and Running Our ARMv8 Binary

QEMU is a virtual machine that is typically used for running non-x86 architecture binaries, such as ARM binaries. But just so that we don't have to spin up a VM evertime we want to run our ARMv8 binary files, let's install a version of QEMU runs statically in the background:

```shell
$ sudo apt install qemu-user-static
```

This command will also install the packages `qemu` and `qemu-user`, which `qemu-user-static` depends on. Same as with the GNU tools we installed earlier, these should be available on other distros that don't use the Aptitude package manager.

Now if we run our compiled ARMv8 executable as we would any other program, it will simply run without any extra steps!

### A Word About Windows Subsystem for Linux (WSL) and QEMU

If you are a Windows user planning on using WSL to write, compile and run ARMv8 code, be advised that the ARMv8 executable will still fail to execute after installing QEMU. This is due to how WSL handles communication between QEMU and the Windows operating system. If you don't want to install Linux on your machine, you can simply run Linux in a VM and it will work as expected.

## Debugging ARMv8 Executables

### Setup

Eventually everyone is going to need a debugger. Unfortunately, as of this writting, the GNU debugger for ARMv8 is still lacking the ability to debug ARMv8 via a static QEMU session (it is also not available to us via the Aptitude package manager). That means that to debug our ARMv8 code we need to spin up an actual QEMU virtual machine to run our code and then debug it via `gdb-multiarch`.

First we need to assemble our code so that it includes important information the debugger needs to do it's job. To do this, we add the `-g` flag to our assembler command:

```shell
$ aarch64-linux-gnu-as -g -o a.o [name of source file]
```

Next, we need make sure that `gdb-multiarch` is installed by using the command `which gdb-multiarch`. If this command returns a file path ending with `gdb-multiarch`, then you can skip this next part. If it does not, install `gdb-multiarch` with the command: 

```shell
$ sudo apt insall gdb-multiarch
```

### Debugging Your Executable

Now that we know our debugger is installed, we can spin up the VM with:

```shell
qemu-aarch64 -g 8888 ./[executable name] &
```

This command tells QEMU to run the executable on an ARMv8 virutal machine and deliver the execution over our computer's port 8888. The ampersand at the end indicates that this VM is to be run in the background while we go do other things.

Now, to start the debugger we use the command:

```shell
$ gdb-multiarch ./[executable name]
```

This will drop you into the `gdb` interface. Since this is a multi-architecture debugger, we need to tell it some important information about the binary file we want to debug:

```shell
(gdb) set arch aarch64
The target architecture is assumed to be aarch64
(gdb) set endian little
The target is assumed to be little endian
```

This tells `gdb` that we are debugging a binary designed for an aarch64 (ARMv8) architecture (which is little endian). Once we have done that, we need to tell `gdb` where it can find the system running the debug target, as it can't run our executable on it's own:

```shell
(gdb) target remote localhost:8888
Remote debugging using localhost:8888
...
```

This tells `gdb` to connect to the QEMU session we started up, served over our computer's port 8888 (it can be any port, but 8888 works). Now we are all set to begin debugging.

Here are some commands you can execute in `gdb` to get information about your program:
 - `list [some label]`: lists the first ten lines found at/near the label [some label].
 - `disassemble [some label]`:  shows breakdown of the first ten lines found at/near the label [some label].
 - `b [line number]`: sets a break point at the specified line\*.
 - `delete [line number]`: removes a break point at the specified line.
 - `run`: runs the debug target until it hits a breakpoint.
 - `info r`: returns the current register values.
 - `continue`: continues the execution of the debug target till the next breakpoint.