restart -f
mem load -i assembler/TwoOperand.mem /ProcessorTB/ram_inst/ram
force -freeze sim:/processortb/inport_data 16'h0005 {5 ns}
force -freeze sim:/processortb/inport_data 16'h0010 {6 ns}
run