import json
from numpy import binary_repr
import logging
import re
import sys

logger = logging.getLogger('assembler')
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)


def assemble(file_name):
    file = open(file_name, "r")
    clean_lines = []
    for line in file:
        clean_line = line.split('#', 1)[0].strip().upper()
        clean_line = re.sub("\s*,\s*", ",", clean_line)
        # print(clean_line)
        if len(clean_line) > 0:
            clean_lines.append(clean_line)
    # print(clean_lines)
    current_addr = 10
    itr = 0
    isa_file = open("isa_commands.json", "r")
    data = json.load(isa_file)
    zero_op_commands = data["zero_operand_commands"]
    one_op_commands = data["one_operand_commands"]
    two_op_commands = data["two_operand_commands"]
    small_imm_commands = data["small_immediate_commands"]
    long_immediate_commands = data["long_immediate_commands"]
    op_codes = data["op_codes"]
    register_codes = data["register_codes"]
    memory = {
        0: "0000000000000000"
    }
    # print(one_op_commands)
    while itr < len(clean_lines):
        line = clean_lines[itr]
        words = re.split("[, ]+", line)
        # print(words)
        current_addr_str = str(current_addr)
        if words[0] == ".ORG":
            current_addr = int(words[1])
            logger.info("Changing address to " + str(current_addr))
        elif zero_op_commands.count(words[0]) > 0:
            memory[current_addr] = op_codes[words[0]] + "00000000000"
            logger.info("At address " + current_addr_str + ": " + words[0])
            assert(len(memory[current_addr]) == 16)
            current_addr += 1
        elif one_op_commands.count(words[0]) > 0:
            memory[current_addr] = op_codes[words[0]] + \
                register_codes[words[1]] + "00000000"
            logger.info("At address " + current_addr_str + ": " + words[0] + " " + words[1])
            assert(len(memory[current_addr]) == 16)
            current_addr += 1
        elif two_op_commands.count(words[0]) > 0:
            memory[current_addr] = op_codes[words[0]] + \
                register_codes[words[1]] + register_codes[words[2]] + "00000"
            logger.info("At address " + current_addr_str +
                        ": " + words[0] + " " + words[1] + " " + words[2])
            assert(len(memory[current_addr]) == 16)
            current_addr += 1
        elif small_imm_commands.count(words[0]) > 0:
            memory[current_addr] = op_codes[words[0]] + \
                register_codes[words[1]] + \
                "000" + \
                binary_repr(int(words[2]), width=5)
            logger.info("At address " + current_addr_str +
                        ": " + words[0] + " " + words[1] + " " + words[2])
            print(len(memory[current_addr]))
            assert(len(memory[current_addr]) == 16)
            current_addr += 1
        elif long_immediate_commands.count(words[0]) > 0:
            memory[current_addr] = op_codes[words[0]] + register_codes[words[1]] + "00000000"
            logger.info("At address " + current_addr_str + ": " + words[0] + " " + words[1])
            assert(len(memory[current_addr]) == 16)
            current_addr += 1
            memory[current_addr] = binary_repr(int(words[2]), 16)
            logger.info("At address " + str(current_addr) + ": " + words[2])
            assert(len(memory[current_addr]) == 16)
            current_addr += 1
        else:
            num = int(words[0])
            if (num >= 0 and num < 65536) or (num >= -32768 and num < 32768):
                memory[current_addr] = binary_repr(num, width=16)
                logger.info("At address " + current_addr_str + ": " + str(num))
                current_addr += 1
        itr += 1
    print("Finished assembling %s!" % file_name)
    return memory


def write_mem(mem, file_name):
    file = open(file_name, "w")
    file.write("// memory data file(do not edit the following line - required for mem load use)\n // instance=/ram_inst/ram\n // format=mti addressradix=d dataradix=b version=1.0 wordsperline=1\n")
    for mem_addr, value in mem.items():
        file.write("\t" + str(mem_addr) + ": " + value + "\n")
    print("Wrote out memory file to %s!" % file_name)


if len(sys.argv) != 3:
    print("Error: please execute the script with the file to assemble as the first argument and the output file as the second argument. Exiting..")
else:
    mem = assemble(sys.argv[1])
    write_mem(mem, sys.argv[2])
