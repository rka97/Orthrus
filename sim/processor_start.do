vsim orthrus.processortb
add wave -position insertpoint  \
sim:/processortb/clk \
sim:/processortb/reset \
sim:/processortb/interrupt \
sim:/processortb/read_mem \
sim:/processortb/write_mem \
sim:/processortb/write_double_mem \
sim:/processortb/mem_address \
sim:/processortb/data_into_mem \
sim:/processortb/data_outof_mem \
sim:/processortb/inport_data \
sim:/processortb/outport_data \
sim:/processortb/IR1_short \
sim:/processortb/IR2_short \
sim:/processortb/new_pc_buff_dec \
sim:/processortb/zero_flag \
sim:/processortb/negative_flag \
sim:/processortb/carry_flag \
sim:/processortb/branch \
sim:/processortb/branch_address \
sim:/processortb/Processor_inst/DecodeStage_inst/register_file_inst/register_load \
sim:/processortb/Processor_inst/DecodeStage_inst/register_file_inst/register_inputs \
sim:/processortb/Processor_inst/DecodeStage_inst/register_file_inst/register_outputs