.data  
T0: .space 4	# the pointers to your lookup tables   
T1: .space 4	# the pointers to your lookup tables 
T2: .space 4	# the pointers to your lookup tables                                                                                     
T3: .space 4	# the pointers to your lookup tables                                                                                     
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

Print:
	slti $t0, $s0, 256
	beq $t0, $zero, Print2
	
	la $a0, message
	li $v0, 4
	syscall
	
	lw $t1, 0($s2)
	li $v0, 1
	move $a0, $t1
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall
	
	addi $s0, $s0, 1
	addi $s2, $s2, 4
	j Print	
	
Print2:
	slti $t0, $t2, 256
	beq $t0, $zero, Print3
	
	la $a0, message2
	li $v0, 4
	syscall
	
	lw $s1, 0($s3)
	li $v0 1
	move $a0, $s1
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall
	
	addi $t2, $t2, 1
	addi $s3, $s3, 4
	j Print2

Print3:		
	slti $t0, $t3, 256
	beq $t0, $zero, Print4
	
	la $a0, message3
	li $v0, 4
	syscall

	lw $s1, 0($s4)
	li $v0 1
	move $a0, $s1
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall
	
	addi $t3, $t3, 1
	addi $s4, $s4, 4
	j Print3	
	
Print4:
	slti $t0, $t8, 256
	beq $t0, $zero, Exit
	
	la $a0, message4
	li $v0, 4
	syscall
	
	lw $s1, 0($s5)
	li $v0 1
	move $a0, $s1
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall
	
	addi $t8, $t8, 1
	addi $s5, $s5, 4
	j Print4
			
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
