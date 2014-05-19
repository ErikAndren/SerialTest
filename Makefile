
FILES=	SerialGen.vhd \
	SerialReader.vhd \
	SerialTest.vhd \
	SerialTestTop.vhd

WORK_DIR="/tmp/work"
MODELSIMINI_PATH=/home/erik/Development/FPGA/Lib/modelsim.ini

CC=vcom
FLAGS=-work $(WORK_DIR) -93 -modelsimini $(MODELSIMINI_PATH)
VLIB=vlib

all: lib work vhdlfiles

lib:
	$(MAKE) -C ../Lib -f ../Lib/Makefile

work:
	$(VLIB) $(WORK_DIR)

clean:
	rm -rf *~ rtl_work *.wlf transcript *.bak

vhdlfiles:
	$(CC) $(FLAGS) $(FILES)
