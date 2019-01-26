.global lenstr
.global cmpstr
.global bzeromem
.global erase_newline
.global split_ws
.global erase_trailing_ws
.global split_ws_reverse
.global cpystr # !!!
.global cpynmem
.global find_sepc
.global catnmem
.global unsigned_int32tos_buf

.text

# function:
# 	int __eax__ cmpstr(const char* __rdi__ buf0, const char* __rsi__ buf1)
# returns: 0 if equal, 1 otherwise
# buf0: first buffer
# buf1: second buffer
cmpstr:
    xorq %rax, %rax
__cmpstr_l0:
    movb (%rdi), %bl
    movb (%rsi), %dl

    testb %bl, %bl
    jz __cmpstr_finish

    testb %dl, %dl
    jz __cmpstr_set_ne

    cmpb %dl, %bl
    jne __cmpstr_set_ne

    addq $1, %rdi
    addq $1, %rsi

    jmp __cmpstr_l0

__cmpstr_finish:
    testb %dl, %dl
    setnz %al
    ret
    
__cmpstr_set_ne:
    movb $1, %al
    ret

# function:
# 	__nothing__ bzeromem(char* __rdi__ buf, size_t __rsi__ bytes)
# returns nothing
# buf: buffer
# bytes: fill for "bytes" bytes
bzeromem:
    xchgq %rsi, %rcx
    xorb %al, %al
__bzeromem_l0:
    movb %al, (%rdi)
    addq $1, %rdi
    subq $1, %rcx
    testq %rcx, %rcx
    jnz __bzeromem_l0

    ret

# function:
#	size_t __rax__ lenstr(const char* __rdi__ buf)
# returns: buf size in bytes
# buf: buffer
#
# WARNING string length DOES NOT include NUL terminator
lenstr:
    xorq %rcx, %rcx
__lenstr_l0:
    movb (%rdi), %bl
    addq $1, %rdi
    addq $1, %rcx
    testb %bl, %bl
    jnz __lenstr_l0
    
    subq $1, %rcx
    subq $2, %rdi

    xchg %rcx, %rax
    ret

# function:
#	__nothing__ erase_newline(char* __rdi__ buf)
# returns nothing
# buf: buffer
erase_newline:
    pushq %rdi

    call lenstr

    popq %rdi
    subq $1, %rax
    addq %rax, %rdi
    
    xorb %al, %al
    movb %al, (%rdi)
    ret

# function:
#	char* __rax__ split_ws(const char* __rdi__ begin, size_t __rsi__ bsz);
# returns: beginning of the space-separated string, 0 if none
# begin: beginning of the buffer
# bsz: buffer size
split_ws:
    xchgq %rsi, %rcx
__split_ws_l0:
    movb (%rdi), %al
    cmpb $32, %al
    je __split_finish
    addq $1, %rdi
    subq $1, %rcx
    testq %rcx, %rcx
    jnz __split_ws_l0

    xorq %rax, %rax
    ret

__split_finish:
    movq %rdi, %rax
    addq $1, %rax
    ret

# function:
# 	__nothing__ erase_trailing_ws(char* __rdi__ buf)
# returns nothing
# buf: buffer which will result in whitespaces (trailing) subs with 0es
erase_trailing_ws:
    pushq %rdi

    call lenstr

    popq %rdi
    subq $1, %rax
    addq %rax, %rdi

__erase_trailing_ws_l0: 
    movb (%rdi), %al
    cmpb $32, %al
    jne __erase_trailing_ws_finish
    xorb %al, %al
    movb %al, (%rdi)
    subq $1, %rdi
    jmp __erase_trailing_ws_l0
    
__erase_trailing_ws_finish: 
    ret

# function:
# 	char* __rax__ split_ws_reverse(const char* __rdi__ beg, const char* __rsi__ end)
# returns: beginning of the ws-separated string
# beg: beginning of the string
# end: end of the string
split_ws_reverse:
__split_ws_reverse_l0:
    movb (%rsi), %al
    cmpb $32, %al
    je __split_ws_finish
    subq $1, %rsi
    cmpq %rsi, %rdi
    je __split_ws_finish
    jmp __split_ws_reverse_l0
    
__split_ws_finish:
    movq %rsi, %rax
    ret

# function:
# 	__nothing__ cpystr(const char* __rdi__ source, char* __rsi__ dest)
# returns nothing
# source: source buffer
# dest: dest buffer
# 
# WARNING: USE WITH CAUTION TO AVOID BUFFER OVERFLOW!
# "source" MUST BE NUL-TERMINATED (0, '\0')
# NUL is copied to dest 
cpystr:
__cpystr_l0:
    movb (%rdi), %al
    movb %al, (%rsi)
    
    testb %al, %al
    jz __cpystr_finish

    addq $1, %rdi
    addq $1, %rsi
    jmp __cpystr_l0

__cpystr_finish:
    retq
    
# function:
# 	__nothing__ cpynmem(const char* __rdi__ source, char* __rsi__ dest, size_t __rdx__ manyb)
# returns nothing
# source: source buffer
# dest: dest buffer
# manyb: how many bytes we should copy?
cpynmem:
    xchgq %rdx, %rcx

__cpynmem_l0:
    movb (%rdi), %al
    movb %al, (%rsi)
    
    addq $1, %rdi
    addq $1, %rsi
    
    subq $1, %rcx
    testq %rcx, %rcx
    jnz __cpynmem_l0

__cpynmem_finish:
    retq
    
# function:
# 	char* __rax__ find_sepc(const char* __rdi__ source, char __rsi__ ch)
# returns an address: where the separator 'ch' was found (from initial address 'source')
# source: where I have to look
# ch: what I have to look for in source
find_sepc:
    pushq %rbx
    pushq %rcx
    pushq %rdx

    movq %rsi, %rcx # altered
    xorq %rdx, %rdx # altered
    movq %rdi, %rax
__find_sepc_loop0:
    movb (%rax), %bl

    testb %bl, %bl
    cmovz %rdx, %rax # if not found
    jz __find_sepc_finish

    cmpb %bl, %cl
    je __find_sepc_finish

    addq $1, %rax
    jmp __find_sepc_loop0

__find_sepc_finish:
    popq %rdx
    popq %rcx
    popq %rbx
    ret 

# function:
# 	__nothing__ catnmem(char* __rdi__ source, const char* __rsi__ what, size_t __rdx__ manyc)
# returns nothing
# source: where to append the string
# what: what I should append
# manyc: how many characeters is the string long?
catnmem:
__catnmem_find_source_end_loop0:
    movb (%rdi), %al
    addq $1, %rdi
    testb %al, %al
    jnz __catnmem_find_source_end_loop0
    
    subq $1, %rdi
    xchgq %rdi, %rsi
    call cpynmem
    ret

# function:
# 	__nothing__ unsigned_int32tos_buf(int32 __rdi__ data, char[10] __rsi__ buf)
# returns nothing
# data: what we have to represent
# buf: where we want to put the representation, should be an array no larger than or less than 10 bytes
unsigned_int32tos_buf:
    xorl %edx, %edx
    movl %edi, %eax
    movl $10, %ebx
    xorl %ecx, %ecx
    
__unsigned_int32tos_buf_loop0:
    xorq %rdx, %rdx
    divl %ebx
    addb $48, %dl
    pushq %rdx

    addq $1, %rcx
    cmpl $10, %eax
    ja __unsigned_int32tos_buf_loop0

    addb $48, %al
    pushq %rax
    addl $1, %ecx

__unsigned_int32tos_buf_loop1:
    popq %rax
    movb %al, (%rsi)
    addq $1, %rsi
    subl $1, %ecx
    jnz __unsigned_int32tos_buf_loop1

    ret
/*
pow:
    pushq %rcx

    movl $1, %eax

    testl %edi, %edi
    jz __pow_finish

    cmp $1, %edi
    cmove %esi, %eax
    je __pow_finish

    movl %edi, %ecx
__pow_loop0:
    mull %esi
    subl $1, %ecx
    testl %ecx, %ecx
    jnz __pow_loop0

__pow_finish:
    popq %rcx
    ret*/
