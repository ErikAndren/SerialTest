
FILES=	SerialPack.vhd \
	SerialCmdParser.vhd \
	RxUart.vhd \
	SerialGen.vhd \
	SerialTestTop.vhd \
	tb.vhd

WORK_DIR="/tmp/work"
MODELSIMINI_PATH=/home/erik/Development/FPGA/Lib/modelsim.ini
VSIM=vsim
TBTOP=tb
VSIM_ARGS=-novopt -t 1ps -lib $(WORK_DIR) -do $(TB_TASK_FILE)
TB_TASK_FILE=simulation/run_tb.tcl


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

isim: all
	$(VSIM) $(TBTOP) $(VSIM_ARGS)
