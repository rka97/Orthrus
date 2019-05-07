.ORG 128
JMP R7
INC R6

.ORG 0
LDM R0, 201     # R0=201 (C9h)
LDM R1, 5     # R1=5 (5h)
LDM R2, 200     # R6=200 (C8h)
IN R3 # should load 7, R3 <= F127h
NOP
NOP
NOP
NOP
NOP
ADD R1, R0 # R0 should contain 206
NOP
NOP
SUB R0, R2 # R2 should contain 206 - 200 = 6 (6h)
NOT R1 # R1 should contain !5 = FFFAh
