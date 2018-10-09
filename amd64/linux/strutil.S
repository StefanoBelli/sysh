.global lenstr
.global cmpstr
.global bzeromem
.global erase_newline
.global split_ws
.global erase_trailing_ws
.global split_ws_reverse

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
