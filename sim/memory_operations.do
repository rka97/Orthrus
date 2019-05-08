restart -f
mem load -i assembler/Memory.mem /ProcessorTB/ram_inst/ram
force -freeze sim:/processortb/inport_data 16'h0019 {3 ns}
force -freeze sim:/processortb/inport_data 16'hFFFF {4 ns}
force -freeze sim:/processortb/inport_data 16'hF320 {5 ns}
run