.data  
T0: .space 4	# the pointers to your lookup tables   
T1: .space 4	# the pointers to your lookup tables 
T2: .space 4	# the pointers to your lookup tables                                                                                     
T3: .space 4	# the pointers to your lookup tables    

s: .word 0xd82c07cd, 0xc2094cbd, 0x6baa9441, 0x42485e3f
rcon: .word  0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01
key: .word 0x6920e299, 0xa5202a6d, 0x656e6368, 0x69746f2a     
rkey: .space 16
t: .space 16                                            
                                
fin: .asciiz "C:\\Users\\zencir\\Documents\\Academic\\CS401\\Project\\tables1.dat"	# put the fullpath name of the file AES.dat here
buffer: .space 300000	# temporary buffer to read from file
newline: .asciiz "\n"    # Define newline symbol

message: .asciiz "Table 1 Element: " 
message2: .asciiz "Table 2 Element: " 
message3: .asciiz "Table 3 Element: " 
message4: .asciiz "Table 4 Element: " 

.text
#open a file for writing
li   $v0, 13       # system call for open file
la   $a0, fin      # file name
li   $a1, 0        # Open for reading
li   $a2, 0
syscall            # open a file (file descriptor returned in $v0)
move $s6, $v0      # save the file descriptor 

#read from file
li   $v0, 14       # system call for read from file
move $a0, $s6      # file descriptor 
la   $a1, buffer   # address of buffer to which to read
li   $a2, 300000     # hardcoded buffer length
syscall            # read from file

move $s0, $v0	   # the number of characters read from the file
la   $s1, buffer   # address of buffer that keeps the characters
la   $s2, T0

addi $s0, $s0, 8

li $v0, 9              # system call for sbrk
li $a0, 300000           # request 256 * 4 bytes = 1024 bytes
syscall
move $s7, $v0          # keep a reference to the start of the heap memory

move $s2, $s7
li $a1, 0
li $t8, 0

Loop:	
	beq $s0, $zero, ResetRegisters # If end of buffer, exit which means we've processed every hexadecimal value in the buffer
	beq $a1, 256, StoreT1Address
	beq $a1, 512, StoreT2Address
	beq $a1, 768, StoreT3Address
			
Initialize:
	addi $a1, $a1, 1
	li $t2, 0 # Represents the processed data in the binary
	li $t3, 0 # Represents the loop counter for the current string to be processed (8 bits)
	li $t4, 0 # Represents the loop counter for the 0x	
		
Process:
	lb $t0, 0($s1)
	addi $s1, $s1, 1
	beq $t0, 48, SkipPrefix # Skip if the 0 in the "0x"
	beq $t0, 120, SkipPrefix # Skip if the x in the "0x"
	
SkipPrefix:
	# print the value	
	slti $t5, $t4, 2
	beq $t5, $zero ProcessLoop
	addi $t4, $t4, 1
	subi $s0, $s0, 1 # Decrement 1 by the $s0 because we processed a byte
	j Process
	
ProcessByte:
	lb $t0, 0($s1) # Load the current buffer address
	addi $s1, $s1, 1 # Increment the buffer pointer
	j ProcessLoop
	
ProcessLoop:
	subi $s0, $s0, 1 # Decrement $s0 because we processed a byte
	subi $t0, $t0, 48 # Substract 48 from the current value 
	slti $t1, $t0, 10 # If the value is less than 10, it is a digit
	bne $t1, $zero, StoreValue # If it is a digit, then jump to the StoreValue procedure
	subi $t0, $t0, 39 # If not a digit, then substract 39 to map the ASCII value to the hexadecimal value
	
StoreValue: 
	sll $t2, $t2, 4 # Shift left 4 bits so that we can make room for the next byte to be processed
	add $t2, $t2, $t0 # Add the binary value to the processed data 
	     
	addi $t3, $t3, 1 # Increment the counter loop by one
	slti $t0, $t3, 8
  	bne $t0, $zero, ProcessByte
	
	sw $t2, 0($s7) # Store the data in the heap
	addi $s7, $s7, 4 # increment heap pointer by 4 bytes
	
	beq $a1, 1024, ProcessLastString
	
	addi $s1, $s1, 2 # Increment buffer pointer by 2 because we skipped the , and space character
	subi $s0, $s0, 2 # Decrement 2 from the $s0 because we skipped the , and space character

	j Loop
	
ProcessLastString:	
	addi $s1, $s1, 2
	subi $s0, $s0, 8
	j Loop

ResetRegisters:
	li $t0, 0
	li $t1, 0
	li $t2, 0
	li $t3, 0
	la $a3, key
	la $t5, rcon
	la $a0, s
	la $a1, rkey
	la $a2, t
	
KeyScheduleFirstIteration:	
	lw $t0, 8($a3) 		# rkey[2]
	srl $t0, $t0, 24 	# rkey[2] >> 24
	andi $t0, $t0, 0xff 	# a =(rkey[2] >> 24) && 0xFF
	
	lw $t1, 8($a3) 		# rkey[2]
	srl $t1, $t1, 16 	# rkey[2] >> 16
	andi $t1, $t1, 0xff 	# b =(rkey[2] >> 16) && 0xFF
	
	lw $t2, 8($a3) 		# rkey[2]
	srl $t2, $t2, 8 		# rkey[2] >> 8
	andi $t2, $t2, 0xff 	# c =(rkey[2] >> 8) && 0xFF
	
	lw $t3, 8($a3) 		# rkey[2]
	andi $t3, $t3, 0xff 	# d =rkey[2] && 0xFF	
	
	sll $t1, $t1, 2
	add $t1, $t1, $s4
	lw $t1, 0($t1)		# T2[b]
	andi $t1, $t1, 0xff 	# T2[b] && 0xFF
	
	lb $t6, 0($t5) 		# rcon[0]
	xor $t1, $t1, $t6 	# (T2[b] && 0xFF)^ rcon[0]
	
	sll $t2, $t2, 2
	add $t2, $t2, $s4
	lw $t2, 0($t2)
	andi $t2, $t2, 0xff	
	
	sll $t3, $t3, 2
	add $t3, $t3, $s4
	lw $t3, 0($t3)
	andi $t3, $t3, 0xff
	
	sll $t0, $t0, 2
	add $t0, $t0, $s4
	lw $t0, 0($t0)
	andi $t0, $t0, 0xff
	
	sll $t1, $t1, 24
	sll $t2, $t2, 16
	sll $t3, $t3, 8
	xor $t1, $t1, $t2
	xor $t1, $t1, $t3
	xor $t1, $t1, $t0 	# tmp = $t1
	
	lw $t0, 0($a3)		# rkey[0]
	xor $t0, $t0, $t1	# rkey[0] ^ tmp
	sw $t0, 0($a1)		# rkey{0] = rkey[0] ^ tmp
	
	lw $t1, 4($a3)		# rkey[1]
	xor $t1, $t1, $t0	# rkey[1] ^ rkey[0]
	sw $t1, 4($a1)		# rkey[1] = rkey[1] ^ rkey[0]
	
	lw $t2, 8($a3)		# rkey[2]
	xor $t2, $t2, $t1	# rkey[2] ^ rkey[1]
	sw $t2, 8($a1)		# rkey[2] = rkey[2] ^ rkey[1]
	
	lw $t3, 12($a3)		# rkey[3]
	xor $t3, $t3, $t2	# rkey[3] ^ rkey[2]
	sw $t3, 12($a1)		# rkey[3] = rkey[3] ^ rkey[2]
	
	move $t8, $a0
	
	lw $t0, 0($a1)
	li $v0, 1
	move $a0, $t0
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall

	lw $t0, 4($a1)
	li $v0, 1
	move $a0, $t0
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall
	
	lw $t0, 8($a1)
	li $v0, 1
	move $a0, $t0
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall	
	
	lw $t0, 12($a1)
	li $v0, 1
	move $a0, $t0
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall	
	
	move $a0, $t8
	
	li $t9, 0
	
Round: 
	lw $t0, 0($a0)	 	# Load the s[0]
	lw $t1, 4($a0) 		# Load the s[1]
	lw $t2, 8($a0) 		# Load the s[2]
	lw $t3, 12($a0) 		# Load the s[3]
	
	# Calculate t[0]
	
	srl $t5, $t0, 24 	# s[0] >> 24
	srl $t6, $t1, 16 	# s[1} >> 16
	srl $t7, $t2, 8		# s[2] >> 8
	andi $t6, $t6, 0xff 	# (s[1] >> 16) && 0xff
	andi $t7, $t7, 0xff	# (s[2] >> 8) && 0xff
	andi $t8, $t3, 0xff	# s[3] && 0xff

	sll $t5, $t5, 2	
	sll $t6, $t6, 2
	sll $t7, $t7, 2	
	sll $t8, $t8, 2
	
	add $t5, $t5, $s5
	lw $t5, 0($t5)
	add $t6, $t6, $s3
	lw $t6, 0($t6)
	add $t7, $t7, $s4
	lw $t7, 0($t7)
	add $t8, $t8, $s2
	lw $t8, 0($t8)
	
	xor $t5, $t5, $t6
	xor $t5, $t5, $t7
	xor $t5, $t5, $t8
	
        lw $t6, 0($a1)
        xor $t5, $t5, $t6
        
       	sw $t5, 0($a2)
       	
       	# Calculate t[1]
       	
       	srl $t5, $t1, 24 	# s[1] >> 24
       	srl $t6, $t2, 16		# s[2] >> 16
       	srl $t7, $t3, 8		# s[3] >> 8
       	andi $t6, $t6, 0xff 	# (s[2] >> 16) && 0xff
	andi $t7, $t7, 0xff	# (s[3] >> 8) && 0xff
	andi $t8, $t0, 0xff	# s[0] && 0xff
	
	sll $t5, $t5, 2	
	sll $t6, $t6, 2
	sll $t7, $t7, 2	
	sll $t8, $t8, 2
       	
	add $t5, $t5, $s5
	lw $t5, 0($t5)
	
	add $t6, $t6, $s3
	lw $t6, 0($t6)
	add $t7, $t7, $s4
	lw $t7, 0($t7)
	add $t8, $t8, $s2
	lw $t8, 0($t8)
	
	xor $t5, $t5, $t6
	xor $t5, $t5, $t7
	xor $t5, $t5, $t8
	
        lw $t6, 4($a1)
        xor $t5, $t5, $t6
        
       	sw $t5, 4($a2)
       	
	# Calculate t[2]
       	
       	srl $t5, $t2, 24 	# s[2] >> 24
       	srl $t6, $t3, 16		# s[3] >> 16
       	srl $t7, $t0, 8		# s[0] >> 8
       	andi $t6, $t6, 0xff 	# (s[3] >> 16) && 0xff
	andi $t7, $t7, 0xff	# (s[0] >> 8) && 0xff
	andi $t8, $t1, 0xff	# s[1] && 0xff
	
	sll $t5, $t5, 2	
	sll $t6, $t6, 2
	sll $t7, $t7, 2	
	sll $t8, $t8, 2
       	
	add $t5, $t5, $s5
	lw $t5, 0($t5)
	add $t6, $t6, $s3
	lw $t6, 0($t6)
	add $t7, $t7, $s4
	lw $t7, 0($t7)
	add $t8, $t8, $s2
	lw $t8, 0($t8)
	
	xor $t5, $t5, $t6
	xor $t5, $t5, $t7
	xor $t5, $t5, $t8
	
        lw $t6, 8($a1)
        xor $t5, $t5, $t6
        
       	sw $t5, 8($a2)       	
       	
       	# Calculate t[3]
       	
       	srl $t5, $t3, 24 	# s[3] >> 24
       	srl $t6, $t0, 16		# s[0] >> 16
       	srl $t7, $t1, 8		# s[1] >> 8
       	andi $t6, $t6, 0xff 	# (s[0] >> 16) && 0xff
	andi $t7, $t7, 0xff	# (s[1] >> 8) && 0xff
	andi $t8, $t2, 0xff	# s[2] && 0xff
	
	sll $t5, $t5, 2	
	sll $t6, $t6, 2
	sll $t7, $t7, 2	
	sll $t8, $t8, 2
       	
	add $t5, $t5, $s5
	lw $t5, 0($t5)
	add $t6, $t6, $s3
	lw $t6, 0($t6)
	add $t7, $t7, $s4
	lw $t7, 0($t7)
	add $t8, $t8, $s2
	lw $t8, 0($t8)
	
	xor $t5, $t5, $t6
	xor $t5, $t5, $t7
	xor $t5, $t5, $t8
	
        lw $t6, 12($a1)
        xor $t5, $t5, $t6
        
       	sw $t5, 12($a2)       	
	
	j KeySchedule
	
KeySchedule:
	slti $t0, $t9, 7
	beq $t0, $zero, Exit
	addi $t9, $t9, 1

	lw $t0, 8($a1) 		# rkey[2]
	srl $t0, $t0, 24 	# rkey[2] >> 24
	andi $t0, $t0, 0xff 	# a =(rkey[2] >> 24) && 0xFF
	
	lw $t1, 8($a1) 		# rkey[2]
	srl $t1, $t1, 16 	# rkey[2] >> 16
	andi $t1, $t1, 0xff 	# b =(rkey[2] >> 16) && 0xFF
	
	lw $t2, 8($a1) 		# rkey[2]
	srl $t2, $t2, 8 		# rkey[2] >> 8
	andi $t2, $t2, 0xff 	# c =(rkey[2] >> 8) && 0xFF
	
	lw $t3, 8($a1) # rkey[2]
	andi $t3, $t3, 0xff # d =rkey[2] && 0xFF	
	
	sll $t1, $t1, 2
	add $t1, $t1, $s4
	lw $t1, 0($t1)		# T2[b]
	andi $t1, $t1, 0xff 	# T2[b] && 0xFF
	
	la $t5, rcon
	sll $t6, $t9, 2	
	add $t5, $t5, $t6
	lb $t6, 0($t5) # rcon[i]
	xor $t1, $t1, $t6 # (T2[b] && 0xFF)^ rcon[i]
	
	sll $t2, $t2, 2
	add $t2, $t2, $s4
	lw $t2, 0($t2)
	andi $t2, $t2, 0xff	
	
	sll $t3, $t3, 2
	add $t3, $t3, $s4
	lw $t3, 0($t3)
	andi $t3, $t3, 0xff
	
	sll $t0, $t0, 2
	add $t0, $t0, $s4
	lw $t0, 0($t0)
	andi $t0, $t0, 0xff
	
	sll $t1, $t1, 24
	sll $t2, $t2, 16
	sll $t3, $t3, 8
	xor $t1, $t1, $t2
	xor $t1, $t1, $t3
	xor $t1, $t1, $t0 # tmp = $t1
	
	lw $t0, 0($a1)		# rkey[0]
	xor $t0, $t0, $t1	# rkey[0] ^ tmp
	sw $t0, 0($a1)		# rkey{0] = rkey[0] ^ tmp
	
	lw $t1, 4($a1)		# rkey[1]
	xor $t1, $t1, $t0	# rkey[1] ^ rkey[0]
	sw $t1, 4($a1)		# rkey[1] = rkey[1] ^ rkey[0]
	
	lw $t2, 8($a1)		# rkey[2]
	xor $t2, $t2, $t1	# rkey[2] ^ rkey[1]
	sw $t2, 8($a1)		# rkey[2] = rkey[2] ^ rkey[1]
	
	lw $t3, 12($a1)		# rkey[3]
	xor $t3, $t3, $t2	# rkey[3] ^ rkey[2]
	sw $t3, 12($a1)		# rkey[3] = rkey[3] ^ rkey[2]
	
	move $t8, $a0
	
	lw $t0, 0($a1)
	li $v0, 1
	move $a0, $t0
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall

	lw $t0, 4($a1)
	li $v0, 1
	move $a0, $t0
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall
	
	lw $t0, 8($a1)
	li $v0, 1
	move $a0, $t0
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall	
	
	lw $t0, 12($a1)
	li $v0, 1
	move $a0, $t0
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall	
	
	move $a0, $t8
	
	j Round

Print:
	# Print t[0]
	
	lw $t0, 0($a2)
	li $v0, 1
	move $a0, $t0
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall

	# Print t[1]
	
	lw $t1, 4($a2)
	li $v0, 1
	move $a0, $t1
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall
	
	# Print t[2]
	
	lw $t2, 8($a2)
	li $v0, 1
	move $a0, $t2
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall

	# Print t[3]
	lw $t3, 12($a2)
	li $v0, 1
	move $a0, $t3
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall
	
	j ExitProgram
			
StoreT1Address:
	la $s3, T1
	move $s3, $s7
	j Initialize
	
StoreT2Address:
	la $s4, T2
	move $s4, $s7
	j Initialize
	
StoreT3Address:
	la $s5, T3
	move $s5, $s7
	j Initialize
	
Exit:
	# Close file
	li $v0,16
	move $a0, $s6
	syscall
	
ExitProgram:
	li $v0,10
	syscall             #exits the program
