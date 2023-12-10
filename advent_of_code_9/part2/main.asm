//IF YOU WANT TO USE THIS, YOU HAVE TO CHANGE THE $21235 VALUE TO REFLECT THEE SIZE OF YOUR FILE IN BYTES
//THE RESULT IS PUSHED UNTO THE STACK AND CAN BE ACCESS VIA BREAKING BEFORE THE EXIT SYSCALL AND SEARCHING UP THE STACK, IT'S THE ONLY PUSHED THING
//IF YOU WANT TO SEE IT ON SCREEN, GO AHEAD AND IMPLEMENT A PRINTF FUNCTION OR LINK TO THE ACTUAL ONE


.text

.globl _start

_start:
	//open
	mov	$0x02, %rax
	mov	$file, %rdi
	mov	$0x00, %rsi # O_RDONLY
	syscall
	call	error_if_negative

	//setup mmap and syscall
	mov	%rax, %r8
	mov	$0x09, %rax
	mov	$0x00, %rdi
	mov	$21235, %rsi #magic number filesize of "input"
	mov	$0x01, %rdx #PROT_READ
	mov	$0x02, %r10 #MAP_PRIVATE
	mov	$0x00, %r9
	syscall
	call	error_if_negative
	
	//save the heap location for now
	push	%rax

	//close fd as it is no longer needed
	mov	$0x03, %rax
	mov	%r8, %rdi
	syscall
	call	error_if_negative


	/*	 			REGISTER OVERVIEW UNTIL (AND INCLUDING) PUSH_NUM
		==============================================================================================
		RAX - HOLDS HEAP ALLOCATED MEM ADDRESS - PUSH IF IN NEED OF REGISTER ELSE MEMORY LEAK
		RDX - HOLDS IF NUM IS NEGATIVE
		R8  - 0X01 IF WE ARE READING THE FINAL NUMBER OF THE SEQUENCE, ELSE 0X00
		R9  - USED AS A COUNTER TO MULTIPLY THE NUMBERS BY 10
		R10 - WHEN PARSING THE NUMBER, USED AS A COUNTER OF WHICH DIGIT WE ARE CURRENTLY PARSING
		R11 - STORES THE PARSED NUMBER, THEN GETS PUSHED UNTO STACK
		R12 - COUNTS CHARACTERS WE HAVE READ FROM CURRENT NUMBER (BEFORE PARSING)
		R13 - COUNTS HOW MANY CHARS WE HAVE READ IN TOTAL (KEEP PERSISTENT!!!)
		R14 - USED FOR STORING PRE-PARSE NUMBERS
		R15 - KEEPS TRACK OF HOW MANY NUMBERS WE HAVE IN CURRENT SET (KEEP FOR SOLVING SET AS WELL)
	*/


	//r14 reads
	//r13 keeps counting
	pop	%rax  #DO NOT TOUCH RAX, IT HOLDS ADDRESS OF HEAP ALLOC
	mov	$0, %rsi
	mov	%rsp, %rbp
	mov	$0x00, %r13 #count chars we have read

new_line:
	mov	$-1, %r12 #count chars in current number reading
	mov	$0, %r8 #0 if at any other num, 1 if at final num
	mov	$0, %r15 #keeps track of how many numbers we have parsed
	mov	$1, %rdx
read_byte:
	mov	$0, %r14
	mov	(%rax, %r13, 1), %r14b
	inc	%r13
	cmp	$45, %r14b #hyphen
	je	hyphen_read
	cmp	$0x20, %r14b
	je	parse_num
	cmp	$0x0a, %r14b
	je	final_num
	sub	$0x30, %r14b
	inc	%r12
	push	%r14
	jmp	read_byte
hyphen_read:
	mov	$-1, %rdx
	jmp	read_byte


final_num:
	mov	$1, %r8	

parse_num:
	mov	$0, %r11
	pop	%r14
	add	%r14, %r11
	cmp	$0, %r12
	je	push_num
	mov	$0, %r10

next_num:
	pop	%r14
	inc	%r10
	mov	%r10, %r9

mult:
	imul	$10, %r14
	dec	%r9
	cmp	$0, %r9
	jne	mult
	add	%r14, %r11
	cmp	%r10, %r12
	je	push_num
	jmp	next_num	

push_num:
	imul	%rdx, %r11
	mov	$1, %rdx
	push	%r11
	mov	$-1, %r12 #count chars in current number reading
	mov	$0, %r14
	inc	%r15
	cmp	$1, %r8
	je	solve_first_step
	jmp	read_byte

solve_first_step:
	imul	$-1, %r15
	mov	%r15, %r14 #how many numbers in current solve
	mov	%rbp, %rdi
	jmp	set_solve
not_first_set:
	inc	%r14
	imul	$8, %r8
	add	%r8, %rdi
set_solve:
	mov	$-1, %r12 #number of zeros
	mov	$-1, %r8   #r8 acts as the index (one indexed) of array of the numbers we parsed (if we took the absolute)
	mov	(%rdi,%r8,8), %r9 #r9 keeping the first number
solving_loop:
	dec	%r8
	mov	(%rdi,%r8,8), %r10 #r10 keeping the second number
	push	%r10
	sub	%r9, %r10
	pop	%r9
	cmp	$0, %r10
	je	equals_zero
	jmp	solution_push
equals_zero:
	dec	%r12
solution_push:
	push	%r10
	cmp	%r12, %r14
	je	solve_upwards
	cmp	%r8, %r14
	je	not_first_set
	jmp	solving_loop	

solve_upwards:
	mov	$0, %r10
	mov	$0, %r11
	sub	$2, %r15
up_first_loop:
	mov	$-1, %r8
	//pop	%r10
	//add	%r11, %r10
	//mov	%r10, %r11
	//dec	%r8
	
up_pop_loop:
	pop	%r9
	dec	%r8
	cmp	%r8, %r14
	jne	up_pop_loop
	mov	%r9, %r10
	sub	%r11, %r10
	mov	%r10, %r11
	dec	%r14
	cmp	%r14, %r15
	je	save_result
	jmp	up_first_loop
	//remember to deallocate heap mem 


save_result:
	add	%r10, %rsi
	cmp	$21235, %r13
	jne	new_line

	push	%rsi
	push	%rax
//deallocate heap
	mov	$11, %rax
	pop	%rdi
	mov	$21235, %rsi
	syscall
	call	error_if_negative

exit:
	//exit
	mov	$60, %rax
	mov	$0, %rsi
	syscall
error:
	//write
	mov 	$1, %rax
	mov 	$1, %rdi
	mov 	$err_msg, %rsi
	mov 	$7, %rdx
	syscall
	jmp	exit

error_if_negative:
	//if rax < 0
	cmp	$0, %rax
	jl	error
	ret


.data

file:
	.ascii "input\0"

err_msg:
	.ascii "Error!\n"
