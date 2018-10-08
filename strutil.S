.global lenstr
.global cmpstr
.global bzeromem
.global dellc

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
#	__nothing__ dellc(char* __rdi__ buf)
# returns nothing
# buf: buffer
dellc:
    call lenstr

    xorb %al, %al
    movb %al, (%rdi)
    ret
