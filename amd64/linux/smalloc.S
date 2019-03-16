.include "macros.S"

.global sysh_smalloc
.global sysh_srealloc
.global sysh_sfree

.data
__blocks_head_addr: .quad 0
__blocks_tail_addr: .quad 0

# IF ARCH IS x86_64, THEN:
#       STRUCT(block_header) : { 
#               DATA_SIZE off 0
#               AVAIL_BLK off 8
#               _NEXT_BLK off 16
#       }
# ENDIF

.text
#
# function:
# 	void* sysh_sbrk(size_t size)
# size: we extend program break "size" bytes
# returns: beginning of your extended "segment"
#
sysh_sbrk:
    movq %rdi, %rsi
    
    sys_brk $0
    
    addq %rsi, %rax
    sys_brk %rax

    retq
    
#
# function:
# 	void* sysh_smalloc(size_t size)
# size: dynamically allocate "size" bytes
# returns: reserved block
#
sysh_smalloc:
    movq %rdi, %rcx

# check if this is the first alloc since program started
    movq (__blocks_head_addr), %rax
    testq %rax, %rax
    jnz __smalloc_find_block_start

__smalloc_request_block:
    pushq %rcx

# request space to the operating system (we still <3 brk)
    addq $24, %rdi
    call sysh_sbrk

    popq %rcx

    testq %rax, %rax
    jz __smalloc_finish__
    
# craft block and add it to the "linked list"
# immediatly return

    movq %rcx, (%rax)
    movq $0, 16(%rax)

    movq (__blocks_tail_addr), %rbx
    testq %rbx, %rbx
    jz __smalloc_append_block
    movq %rax, 16(%rbx)

__smalloc_append_block:
    movq %rax, (__blocks_tail_addr)

    movq (__blocks_head_addr), %rbx
    testq %rbx, %rbx
    jnz __smalloc_finish

    movq %rax, (__blocks_head_addr)

    jmp __smalloc_finish

__smalloc_find_block:
    movq 16(%rax), %rax
    testq %rax, %rax
    jz __smalloc_request_block

__smalloc_find_block_start:
    movq (%rax), %rdx
    cmpq %rcx, %rdx
    jl __smalloc_find_block

    movq 8(%rax), %rdx
    testq %rdx, %rdx
    jz __smalloc_find_block

__smalloc_finish:
    movq $0, 8(%rax)
    addq $24, %rax
__smalloc_finish__:
    retq
    
#
# function:
# 	void sysh_sfree(void* block)
# block: block to free
#
sysh_sfree:
    subq $16, %rdi
    movq $1, (%rdi)
    retq
