restart -f
mem load -i assembler/Branch.mem /ProcessorTB/ram_inst/ram
force -freeze sim:/processortb/inport_data 16'h0030 {3 ns}
force -freeze sim:/processortb/inport_data 16'h0050 {4 ns}
force -freeze sim:/processortb/inport_data 16'h0100 {5 ns}
force -freeze sim:/processortb/inport_data 16'h0300 {6 ns}
force -freeze sim:/processortb/inport_data 16'h0200 {19 ns}
run