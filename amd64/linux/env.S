.extern lenstr
.extern cpystr
.extern cmpstr
.extern bzeromem
.extern cpynmem

.global sysh_getenv
.global sysh_unsetenv
.global sysh_setenv
.global sysh_envcount

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

# function:
# 	int __eax__ sysh_envcount(char** __rdi__ envp)
# returns: number of set variables
# envp: environmental variables array, the last address must be 0 (NULL, (void*)0)
sysh_envcount:
    xorl %eax, %eax
__envcount_l0:
    movq (%rdi), %rbx
    addl $1, %eax
    addq $8, %rdi
    testq %rbx, %rbx
    jnz __envcount_l0

    subl $1, %eax
    retq

# function:
# 	int __eax__ sysh_unsetenv(const char* __rdi__ lval, char** __rsi__ envp)
# returns: 1 if variable deleted, 0 if not found
# lval: the left value of the pair (aka the key of the pair, env var name)
# envp: environmental variables array, the last address must be 0 (NULL, (void*) 0)
sysh_unsetenv:
    pushq %rsi

    call sysh_getenv
    
    testq %rax, %rax
    popq %rsi
    jz __unsetenv_finish

    pushq %rbx
    pushq %rax

    movq %rax, %rdi
    callq lenstr

    popq %r11
    movq %r11, %rdi
    movq %rax, %rsi
    callq bzeromem

    popq %rbx
    movq %r11, %rax
    
    movq %rax, %rdi
    callq sysh_sfree

    xorq %rax, %rax

    movq (%rbx), %rsi
    movq %rax, (%rsi)
    
    movq %rbx, %rsi
__unsetenv_remove_pair_l0:
    movq %rsi, %rdi
    addq $8, %rsi
    movq (%rsi), %rax
    movq %rax, (%rdi)
    
    testq %rax, %rax
    jnz __unsetenv_remove_pair_l0

    movq $1, %rax

__unsetenv_finish:
    retq
    
# function:
# 	int __eax__ sysh_setenv(const char* __rdi__ lval, const char* __rsi__ rval, char** __rdx__ envp)
# returns: 1 if variable changed, 0 if not found or could not change (reasons listed below)
# lval: the left value of the pair (aka the key of the pair, env var name)
# rval: the right value of the pair (aka the value of the pair, env var value)
# envp: environmental variables array, the last address must be 0 (NULL, (void*) 0)
# 
# sysh_setenv will NOT change a variable's value:
# 	* if NEW rval is larger than the ACTUAL rval of the key
# 	* if lval does not exist at all
# reason:
# 	yaaaa no memory allocator available :(
sysh_setenv:
    movq %rsi, %r10

    movq %rdx, %rsi
    callq sysh_getenv

    testq %rax, %rax
    jz __setenv_set_newkey

    movq %rbx, %r14

    movq %rax, %rdi
    callq lenstr

    movq %rax, %rdx

    movq %r10, %rdi
    callq lenstr
    movq %rax, %r12
    
    xorq %rax, %rax

    cmpq %rdx, %r12
    ja __setenv_finish

    movq (%r14), %rdi
    callq lenstr
    
    addq $1, %rdi
    subq %rdx, %rdi
    movq %rdx, %rsi
    
    movq %rdi, %r14
    callq bzeromem

    movq %r10, %rdi
    movq %r14, %rsi
    movq %r12, %rdx
    callq cpynmem
    
    movq $1, %rax
__setenv_set_newkey:
__setenv_finish:
    retq 
