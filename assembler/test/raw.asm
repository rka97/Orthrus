.ORG 0
10

.ORG 10
LDM R0, 201     # R0=201 (C9h)0
LDM R1, 5     # R1=5 (5h)1
LDM R2, 200     # R6=200 (C8h)2
LDM R3, 8        #3
INC R3          #4
PUSH R1      
PUSH R2    
POP R6  #has 200
POP R7  #has 5
ADD R7, R0          #6
ADD R3,R0
ADD R0, R6          #7
ADD R1, R6           #8


