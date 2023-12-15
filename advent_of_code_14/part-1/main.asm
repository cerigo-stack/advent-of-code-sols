.globl	_start

//answer on register r13
//remember to change filesize variable


_start:
	//open
	mov	$2, %rax
	mov	$file, %rdi
	mov	$0, %rsi #O_RDONLY
	syscall
	call	error_if_negative

	//setup mmap and syscall
	mov	%rax, %r8
	mov	$0x09, %rax
	mov	$0x00, %rdi
	mov	$file_size, %rsi
	mov	(%rsi), %rsi 
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
	

	//taking back heap address
	pop	%rcx
	mov	$1, %r9  #line_length	

	//read byte by byte to determine line length
	read_line_by_byte:
	movb	(%rcx,%r9,1), %r8b
	cmp	$0x0a, %r8b  #newline
	je	line_length_found
	inc	%r9
	jmp	read_line_by_byte

	//calculate collumn length
	line_length_found:
	mov	$file_size, %rax
	mov	(%rax), %rax
	cqto
	inc	%r9	#because we need length not index
	idiv	%r9

	//the current value of the slide is the collumn length
	//if we find a O, that takes the collumn length value (it slides down) and it is decremented by one (so an O in line 3 would slide down to line 1 aka collumn length 10)
	//if we find an # set slide value to this -1 because it can only slide to one above
	//we cannot touch rcx because it would lead to memory leak or r9 cause we would lose how many chars in a line
	//also rax because we need to know how many chars in a collumn
	mov	$0, %r10	#what_to_read
	mov	%rax, %r11	#slide_value
	mov	%rax, %r12	#current_iteration (start from max, step -1, until 0)
	mov	$0, %r13	#sum
	mov	$0, %r14	#current_collumn
	jmp	read_collumn_by_byte
	next_collumn:
	inc	%r14
	cmp	%r14, %r9
	je	deallocate_heap
	mov	%r14, %r10	#what_to_read
	mov	%rax, %r12	#current_iteration (start from max, step -1, until 0)
	mov	%rax, %r11	#slide_value
	
	read_collumn_by_byte:
	movb	(%rcx,%r10,1), %r8b
	add	%r9, %r10
	dec	%r12
	cmp	$0x4f, %r8b	#capital o
	je	O_detected
	cmp	$0x23, %r8b	# pound
	je	pound_detected
	continue_collumn_read:
	cmp	$0, %r12
	je	next_collumn
	jmp	read_collumn_by_byte

	
	O_detected:
	add	%r11, %r13
	dec	%r11
	jmp	continue_collumn_read

	pound_detected:
	mov	%r12, %r11
	jmp	continue_collumn_read
	

	

	deallocate_heap:	
	//deallocate heap
	mov	$11, %rax
	mov	%rcx, %rdi
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
	.quad 10100
file:	
	.ascii "input\0"
err_msg:
	.ascii "Error!\n"

