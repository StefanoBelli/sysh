#
# smalloc.S 
# 
# 	Simple Malloc implementation for sysh, libc-independent
#

# IF ARCH IS x86_64 THEN 
#	STRUCT (block_header) : {
#		DATA_SIZE off 0
#		_FREE_BLK off 8
# 		_NEXT_BLK off 16
# 	}
# ENDIF

.include "macros.S"

.extern cpynmem

.global sysh_smalloc
.global sysh_srealloc
.global sysh_sfree

.data
blocks_head: .quad 0
blocks_tail: .quad 0

.text
#
# __private__ function:
# 		void* __rax__ _sysh_append_new_block(size_t __rdi__ size)
# size: bytes we should allocate
# returns: beginning of allocated region (includes 24-byte header)
#
_sysh_append_new_block:
	movq %rdi, %rsi

	addq $24, %rdi
	callq sysh_mmapit

	testq %rax, %rax
	jz __append_new_block_finish

	movq %rsi, (%rax) 	# block_header->DATA_SIZE
	xorq %rsi, %rsi
	movq %rsi, 16(%rax)	# block_header->_NEXT_BLK

	movq $blocks_tail, %rbx
	movq (%rbx), %rcx

	testq %rcx, %rcx
	jz __append_new_block_this_is_first

	movq %rax, 16(%rcx)
	movq %rax, (%rbx)
	
	jmp __append_new_block_finish

__append_new_block_this_is_first:
	movq %rax, (%rbx)
	movq $blocks_head, %rbx
	movq %rax, (%rbx)

__append_new_block_finish:
	retq

#
# __private__ function
#		void* __rax__ sysh_mmapit(size_t __rdi__ bytes)
# bytes: get "bytes" size anonymous memory mapping
# returns: beginning of requested area
#
sysh_mmapit:
	addq %rsi, %rax
	sys_mmap $0, %rax, $3, $34, $0, $0
	retq

#
# function:
#		void* __rax__ sysh_smalloc(size_t __rdi__ req_size)
# req_size: request "req_size" bytes to be allocated
# returns: beginning of dynamically allocated memory
# 
sysh_smalloc:
	xorq %rax, %rax
	testq %rdi, %rdi
	jz __smalloc_failure_finish

# check if this is the first alloc
	movq $blocks_head, %rbx
	movq (%rbx), %rax

	testq %rax, %rax
	jz __smalloc_append_new_block

# walk through the linked list
__smalloc_lookfor_block:

# block must be free
	movq 8(%rax), %rdx
	testq %rdx, %rdx
	jz __smalloc_next_block

# block size must be >= than requested
	movq (%rax), %rdx
	subq $24, %rdx
	cmpq %rdx, %rdi
	jle __smalloc_finish

__smalloc_next_block:
	movq 16(%rax), %rdx
	movq %rdx, %rax
	testq %rax, %rax
	jnz __smalloc_lookfor_block

# we couldn't find any available block!
# ... or this is the first allocation
__smalloc_append_new_block: # move blk size to rdi before jumping
	callq _sysh_append_new_block

	testq %rax, %rax
	jz __smalloc_failure_finish

# end
__smalloc_finish:
	xorq %rsi, %rsi
	movq %rsi, 8(%rax)
	addq $24, %rax
__smalloc_failure_finish:
	retq

#
# function:
#		__nothing__ sysh_sfree(void* __rdi__ block)
# block: block which has to be flagged as free
# returns nothing
#
sysh_sfree:
	subq $24, %rdi
	movq $1, 8(%rdi)

	retq

#
# function:
# 	void* __rax__ sysh_realloc(void* __rdi__ oldblk, size_t __rsi__ newsize)
# oldblk: old block to resize
# newsize: new size request, we will bring new space to you :)
# returns: new block
#
sysh_srealloc:
	xorq %rax, %rax

# check if oldblock is null
	testq %rdi, %rdi
	jz __srealloc_finish

	movq %rdi, %rax # rax contains oldblk

# check if newsize is 0
	testq %rsi, %rsi
	jz __srealloc_finish

	subq $24, %rax # get oldblk header
	movq 16(%rax), %r10 # r10 : next block
	movq 8(%rax), %rdx # rdx : is freed?
	movq (%rax), %rcx # rcx : size
	subq $24, %rcx
	addq $24, %rax

# check if block is freed
	testq %rdx, %rdx
	xchgq %rdx, %rax # will return (void*)1
	jnz __srealloc_finish
	xchgq %rdx, %rax

# check if block size is greater or equal than requested size
	cmpq %rcx, %rsi
	jle __srealloc_finish
	
# check if block is the last in the linked list
	subq $24, %rax
	movq $blocks_tail, %rbx
	movq (%rbx), %r9
	cmpq %r9, %rax
	jne __srealloc_attempt_merge_nextblock

	movq %rax, %r13

# get new space
	subq %rcx, %rsi
	movq %rsi, %rdi
	movq %rcx, %r12
	addq %rsi, %r12
	callq sysh_mmapit

	testq %rax, %rax
	jz __srealloc_finish

	movq %r13, %rax

	addq $24, %rcx
	addq %r12, %rcx
	movq %rcx, (%rax)
	addq $24, %rax

	jmp __srealloc_finish	

# merge the free next block with this
__srealloc_attempt_merge_nextblock:
	movq 16(%rax), %r13
	movq 8(%r13), %r12

	testq %r12, %r12
	jz __srealloc_get_new_block

	movq 16(%r13), %rbx
	movq %rbx, 16(%rax)

	movq (%r13), %rbx
	subq $24, %rbx
	addq %rbx, (%rax)

	addq $24, %rax
	jmp __srealloc_finish

# we tried our best :(
# need to do the bad job
# there is still chance that malloc finds a free block
# instead of allocating new one
__srealloc_get_new_block:
	addq $24, %rax

	movq %rax, %r13
	movq %rsi, %r12

	movq %rsi, %rdi
	callq sysh_smalloc

	testq %rax, %rax
	jz __srealloc_finish

	movq %rax, %r8

	movq %r13, %rdi
	movq %rax, %rsi
	movq %r12, %rdx
	callq cpynmem

	movq %r8, %rax

	movq %r13, %rdi
	callq sysh_sfree

__srealloc_finish:
	retq

