restart -f
mem load -i assembler/Branch.mem /ProcessorTB/ram_inst/ram
force -freeze sim:/processortb/inport_data 16'h0030 {3 ns}
force -freeze sim:/processortb/inport_data 16'h0050 {4 ns}
force -freeze sim:/processortb/inport_data 16'h0100 {5 ns}
force -freeze sim:/processortb/inport_data 16'h0300 {6 ns}
force -freeze sim:/processortb/inport_data 16'h0200 {14 ns}
force -freeze sim:/processortb/interrupt 1 {12 ns}
force -freeze sim:/processortb/interrupt 0 {13 ns}
run