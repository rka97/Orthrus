restart -f
mem load -i assembler/OneOperand.mem /ProcessorTB/ram_inst/ram
force -freeze sim:/processortb/inport_data 16'h0005 {9 ns}
force -freeze sim:/processortb/inport_data 16'h0010 {10 ns}
run