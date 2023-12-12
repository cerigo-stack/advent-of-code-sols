//THIS IS REALLY MESSY CODE BUT IT GETS THE JOB DONE
//SHOULD YOU WANT TO USE IT SET THE FILE_SIZE VARIABLE IN THE .DATA SECTION TO YOUR FILE SIZE


.globl _start


_start:	
	//open input
	mov	$0x02, %rax
	mov	$file, %rdi
	mov	$0x00, %rsi # O_RDONLY
	syscall
	call	error_if_negative

	//setup mmap and syscall
	mov	%rax, %r8
	mov	$0x09, %rax
	mov	$0x00, %rdi
	mov	$file_size, %rsi 
	mov	$0x02, %rdx #PROT_WRITE
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



	//heap memory address
	pop	%r8
	mov	$0, %r13  #keeps count of galaxies
	mov	$1, %r12 #do this for later division
	//using r11 as as line counter
	mov	$0, %r11
	//process first row, store how many bytes there are in r9 (length of row), and push all asteroid locations to stack
	mov	$0, %r9
	
	row_loop:
	mov	(%r8,%r9,1), %r10b
	cmp	$0x23, %r10b
	je	galaxy_detected
	cmp	$0x0a, %r10b
	je	end_of_line
	row_loop_end:
	inc	%r9
	jmp	row_loop

	galaxy_detected:
	sub	%r11, %r9
	cmp	$1, %r12
	je	first_line_galaxy_detection
	mov	%r9, %rax
	cqto
	idiv	%r12
	jmp	push_galaxy
	first_line_galaxy_detection:
	mov	%r9, %rdx
	push_galaxy:
	push	%rdx            #galaxy x
	add	%r11, %r9
	push	%r11	       #galaxy y
	inc	%r13
	jmp	row_loop_end
		

	end_of_first_line:
	inc	%r9  #because we are converting index to length +1 because of the newline char
	mov	$file_size, %rax
	mov	(%rax), %rax
	cqto
	idiv	%r9
	mov	%rax, %r12
	inc	%r11
	mov	%r9, %rbx #rbx is now how many chars in each line (to void multiplying later down the line)
	jmp	row_loop
	//r12 now holds how many lines we have

	end_of_line:
	cmp	$0, %r11
	je	end_of_first_line
	inc	%r11
	cmp	%r12, %r11
	je	create_empty_row_collumn_galaxy_array
	inc	%r9
	jmp	row_loop
	
	//yequals0 used below
	yequals0:
	mov	%rbx, %r14
	inc	%r14
	movb	$1, (%r8, %r14, 1)
	inc	%r9
	jmp	do_x

	create_empty_row_collumn_galaxy_array:	
	//r14, r15 used here for now 
	imul	$2, %r13
	mov	$0, %r9
	
	empty_galaxy_array_loop:	
	mov	(%rsp, %r9, 8), %r14
	cmp	$0, %r14
	je	yequals0
	imul	%rbx, %r14
	movb	$1, (%r8, %r14, 1)
	inc	%r9
	do_x:
	mov	(%rsp, %r9, 8), %r14
	movb	$1, (%r8, %r14, 1)
	inc	%r9
	cmp	%r9, %r13
	jne	empty_galaxy_array_loop
		
	//now we recalculate distances
	//first lines
	get_line:
	mov	$0, %r14
	mov	%rbx, %r15
	dec	%r12
	cmp	$0, %r12
	je	last_iteration_recalculate
	cmp	$-1, %r12
	je	get_collumn_prep
	
	imul	%r12, %r15

	movb	(%r8, %r15, 1), %r14b
	jmp	recalculation
		
	last_iteration_recalculate:
	movb	1(%r8, %rbx, 1), %r14b
	

	recalculation:
	cmp	$1, %r14
	je	get_line
	
	mov	$0, %r9
	mov	(%rsp, %r9, 8), %r14
	cmp	%r14, %r12
	jge	next_star_recalc_y	
	addq	$999999, (%rsp, %r9, 8)
	next_star_recalc_y:
	add	$2, %r9
	mov	(%rsp, %r9, 8), %r14
	cmp	%r9, %r13
	je	get_line
	cmp	%r14, %r12
	jge	next_star_recalc_y	
	addq	$999999, (%rsp, %r9, 8)
	jmp	next_star_recalc_y


	get_collumn_prep:
	dec	%rbx
	
	get_collumn:
	dec	%rbx
	cmp	$-1, %rbx
	je	final_calculation
	mov	$0, %r14
	mov	(%r8,%rbx, 1) , %r14b
	cmp	$1, %r14b
	je	get_collumn

	
	mov	$0, %r9
	mov	8(%rsp, %r9, 8), %r14
	cmp	%r14, %rbx
	jge	next_star_recalc_x	
	addq	$999999, 8(%rsp, %r9, 8)
	next_star_recalc_x:
	add	$2, %r9
	mov	8(%rsp, %r9, 8), %r14
	cmp	%r9, %r13
	je	get_collumn
	cmp	%r14, %rbx
	jge	next_star_recalc_x	
	addq	$999999, 8(%rsp, %r9, 8)
	jmp	next_star_recalc_x
	
	//now all stars are in their final position and we are ready to calculate the paths
	final_calculation:
	mov	$0, %rax

	final_loop:
	pop	%r14
	pop	%r15
	sub	$2 ,%r13
	cmp	$0, %r13
	je	deallocate_heap
	mov	$-2, %r12
	
	star_loop_distance_calculator:
	add	$2, %r12
	cmp	%r12, %r13
	je	final_loop
	mov	(%rsp, %r12, 8), %r11
	sub	%r14, %r11
	cmp	$0 ,%r11
	jl	negative_dif_y
	jmp	calc_x
	negative_dif_y:
	imul	$-1, %r11

	calc_x:
	add	%r11, %rax	
	mov	8(%rsp, %r12, 8), %r11
	sub	%r15, %r11
	cmp	$0, %r11
	jl	negative_dif_x
	jmp	x_y_calculated
	negative_dif_x:
	imul	$-1, %r11
	x_y_calculated:
	add	%r11, %rax
	jmp	star_loop_distance_calculator	





	deallocate_heap:	
	//deallocate heap
	call	reg_dump
	mov	$11, %rax
	mov	%r8, %rdi
	mov	$file_size, %rsi
	syscall
	call	error_if_negative


	//exit
	exit:
	mov	$60, %rax
	mov	$0, %rdi
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
file_size:
	.quad 19740
file:	
	.ascii "input\0"
err_msg:
	.ascii "Error!\n"
