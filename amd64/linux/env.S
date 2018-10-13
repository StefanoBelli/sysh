.extern lenstr
.extern cpystr

.global sysh_getenv

.text
# function:
# 	char* __rax__ sysh_getenv(const char* __rdi__ lval, const char** __rsi__ envp)
# returns: beginning of the associated value to lval
# lval: the left value of the pair (aka the key of the pair, env var name)
# envp: environmental variables array, the last address must be 0 (NULL, (void*) 0)
sysh_getenv:
    movq %rdi, %rdx # lval
    movq %rsi, %rbx # envp

__getenv_getpair_l0:
    pushq %rbx
    pushq %rdx

    xchgq %rbx, %r15

    movq (%r15), %rdi
    call lenstr

    xchgq %r15, %rbx

    addq $1, %rax
    movq %rax, %rcx # preserve rax

    subq %rax, %rsp

    movq (%rbx), %rdi
    movq %rsp, %rsi
    call cpystr

    movq %rsp, %r9
__getenv_getpair_l0_getname_l1:
    movb (%r9), %al
    cmpb $61, %al
    je __getenv_getpair_l0_finish_l1
    addq $1, %r9
    jmp __getenv_getpair_l0_getname_l1
    
__getenv_getpair_l0_finish_l1:
    xorb %al, %al
    movb %al, (%r9)

    movq %rsp, %rdi
    movq %rdx, %rsi
    call cmpstr

    movq %rax, %r11

    movq %rcx, %rax # restore rax
    addq %rax, %rsp

    popq %rdx
    popq %rbx

    testq %r11, %r11
    jz __getenv_finish_value_found

    addq $8, %rbx
    movq (%rbx), %r9
    testq %r9, %r9
    jz __getenv_finish_value_not_found

    jmp __getenv_getpair_l0
    
__getenv_finish_value_found:
    addq $1, %r9
    movq %r9, %rax
    retq

__getenv_finish_value_not_found:
    xorq %rax, %rax
    retq
