## config.mk

EXE =

## toolchain
YOSYS = yosys$(EXE)
PR    = /usr/bin/p_r/p_r$(EXE)
OFL   = openFPGALoader$(EXE)

GTKW = gtkwave
IVL = iverilog
VVP = vvp
IVLFLAGS = -Winfloop -g2012 -gspecify -Ttyp

## simulation libraries
CELLS_SYNTH = /usr/local/share/yosys/gatemate/cells_sim.v
CELLS_IMPL = /usr/bin/p_r/cpelib.v

## target sources
VLOG_SRC = $(shell find ./src/ -type f \( -iname \*.v -o -iname \*.sv \))
VHDL_SRC = $(shell find ./src/ -type f \( -iname \*.vhd -o -iname \*.vhdl \))

## misc tools
RM = rm -rf

## toolchain targets
synth: synth_vlog

synth_vlog: $(VLOG_SRC)
	$(YOSYS) -qql log/synth.log -p 'read -sv $^; synth_gatemate -top $(TOP) -nomx8 -vlog net/$(TOP)_synth.v'

synth_vhdl: $(VHDL_SRC)
	$(YOSYS) -ql log/synth.log -p 'ghdl --warn-no-binding -C --ieee=synopsys $^ -e $(TOP); synth_gatemate -top $(TOP) -nomx8 -vlog net/$(TOP)_synth.v'

impl:
	$(PR) -i net/$(TOP)_synth.v -o $(TOP) $(PRFLAGS) > log/$@.log

jtag:
	$(OFL) $(OFLFLAGS) -b gatemate_evb_jtag $(TOP)_00.cfg

jtag-flash:
	$(OFL) $(OFLFLAGS) -b gatemate_evb_jtag -f --verify $(TOP)_00.cfg

spi:
	$(OFL) $(OFLFLAGS) -b gatemate_evb_spi -m $(TOP)_00.cfg

spi-flash:
	$(OFL) $(OFLFLAGS) -b gatemate_evb_spi -f --verify $(TOP)_00.cfg

svgnetlist:
	@for svgtop in ${SVGNETLISTS}; do \
		yosys -p "prep -top $${svgtop}; write_json svg_netlist/$${svgtop}.json" src/*.v; \
		netlistsvg svg_netlist/$${svgtop}.json -o svg_netlist/$${svgtop}.svg; \
		yosys -p "prep -top $${svgtop} -flatten; write_json svg_netlist/flat_$${svgtop}.json" src/*.v; \
		netlistsvg svg_netlist/flat_$${svgtop}.json -o svg_netlist/flat_$${svgtop}.svg; \
	done

all: synth svgnetlist impl jtag

clean:
	$(RM) log/*.log
	$(RM) net/*_synth.v
	$(RM) *.history
	$(RM) *.txt
	$(RM) *.refwire
	$(RM) *.refparam
	$(RM) *.refcomp
	$(RM) *.pos
	$(RM) *.pathes
	$(RM) *.path_struc
	$(RM) *.net
	$(RM) *.id
	$(RM) *.prn
	$(RM) *_00.v
	$(RM) *.used
	$(RM) *.sdf
	$(RM) *.place
	$(RM) *.pin
	$(RM) *.cfg*
	$(RM) *.cdf
	$(RM) svg_netlist/*
