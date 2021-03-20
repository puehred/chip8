# chip8
A chip-8 interpreter for Sharp PC-1350, PC-1360 and PC-2500 pocket computers

To build the project you need GNU make and this assembler:

http://shop-pdp.net/ashtml/asxxxx.htm

You also need a python script named ihx2bas.py from this repository:

https://github.com/puehred/ihx2bas

First, you have to decide, for which model you want to build chip-8:

arthur@deepthought:~/sharp/chip8$ ./configure.sh 
usage: configure.sh [ PC-1350 | PC-1360 | PC-2500 ]
arthur@deepthought:~/sharp/chip8$ ./configure.sh PC-1350

This will create a file 'target.h'. Now build the BASIC loader:

arthur@deepthought:~/sharp/chip8$ make basldr
as61860 -los chip8.asm
...
ihx2bas.py -fast -p `tail -n 1 target.h | tr ';' ' '` chip8.ihx|tr '\n' '\r' > chip8.bas && cat basldr/basldr_ext.bas|tr '\n' '\r' >> chip8.bas

Now you get a file 'chip8.bas' which you can transfer to your pocket computer e.g. wath a CE-130T interface ore with a cassette interface.

Have fun!

