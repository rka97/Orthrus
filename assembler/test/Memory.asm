# all numbers in hex format
# we always start by reset signal
#this is a commented line
.ORG 0  #this means the the following line would be  at address  0 , and this is the reset address
10
#you should ignore empty lines

.ORG 2  #this is the interrupt address
100

.ORG 10
in R2        # R2=19 add 19 in R2
NOP

in R3        # R3=FFFF
NOP

in R4        # R4=F320
NOP

LDM R1,5     # R1=5
LDM R0,201     # R0=201

LDM R6,200     # R6=200
NOP # LDM R1, 5 in Decode

NOP # LDM R1, 5 in Execute
NOP

NOP # LDM R1, 5 in MA
NOP

NOP # LDM R1, 5 in WB
PUSH R1      # SP=FFFFFFFE,M[FFFFFFFF]=5

PUSH R2      # SP=FFFFFFFD,M[FFFFFFFE]=19
NOP # PUSH R1 in Decode

NOP # ~ EX
NOP

NOP # ~ MA
NOP

NOP # ~ WB
POP R1       # SP=FFFFFFFE,R1=19

POP R2       # SP=FFFFFFFF,R2=5
NOP

NOP # POP R2 in Decode
NOP

NOP # ~ in EX
NOP

NOP # ~ in MA
NOP

STD R2,R6   # M[200]=5
STD R1,R0   # M[201]=19

NOP 
NOP # STD R1, R0 in Decode

NOP
NOP # ~ EX

NOP
NOP # ~ MA

LDD R0,R3   # R3=19
LDD R6,R4   # R4=5
