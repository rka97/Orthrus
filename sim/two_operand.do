restart -f
mem load -i assembler/TwoOperand.mem /ProcessorTB/ram_inst/ram
force -freeze sim:/processortb/inport_data 16'h0005 {3 ns}
force -freeze sim:/processortb/inport_data 16'h0019 {4 ns}
force -freeze sim:/processortb/inport_data 16'hFFFF {5 ns}
force -freeze sim:/processortb/inport_data 16'hF320 {6 ns}
run