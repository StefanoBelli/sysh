.extern sysh_getenv
.extern bzeromem
.extern cpynmem
.extern catnmem
.extern lenstr
.extern find_sepc

.include "macros.S"

.data
path: .asciz "PATH"

.global sysh_execvp
.text

# function:
# 	int __eax__ sysh_execvp(const char* __rdi__ program, const char** __rsi__ argv, char** __rdx__ envp)
#  'sysh' version of execvp.
#  attempts to launch program first, then looks inside PATH
# returns: whatever execve will return :)
#           * if retval is 1 this means that program was not found in PATH (aka execve failure)
#           * if retval is 2 means that sysh_getenv failed
#           * if retval is 0 means that program was correctly executed
# program: program to launch
# argv: program's cmdline argv
# envp: environmental set

sysh_execvp:
    pushq %rdi
    pushq %rsi
    pushq %rdx

    sys_execve %rdi, %rsi, %rdx
    testl %eax, %eax
    jz __sysh_execvp_finish # first execvp attempt
			    # execvp failure, proceed

# get PATH from envp
    movq $path, %rdi
    movq (%rsp), %rsi
    call sysh_getenv

    movq $1, %rdx
    testq %rax, %rax
    cmovz %rdx, %rax # getenv failure
    jz __sysh_execvp_finish

    movq %rax, %r11

    movq 16(%rsp), %rdi
    call lenstr
    
    movq %rax, %r8

__sysh_execvp_loop0:
    movq %r11, %rdi
    movq $58, %rsi
    call find_sepc 

    movq $1, %rdx #check if end was reached
    testq %rax, %rax
    cmovz %rdx, %rax
    jz __sysh_execvp_finish

# r11: path beginning
# rax: current
# 16(rsp): program
# r8: program len

    movq %rax, %rdx # rdx: curptr
    movq %rax, %rcx # rcx: another copy of curptr
    subq %r11, %rax # rax: pathlen
    addq $2, %rax # rax: add two more for NUL and /
    addq %r8, %rax  # rax: contains total length

    movq %rax, %rbx
    pushq %rdx

    subq %rbx, %rsp # reserve space for the string (e.g. "/usr/bin/clear\0")

    movq %rcx, %r12

    movq %rsp, %rdi
    movq %rbx, %rsi
    call bzeromem

    movq %r11, %rdi
    movq %rsp, %rsi
    subq %r11, %r12
    movq %r12, %rdx
    call cpynmem
    
    movb $47, (%rsp, %r12,)

    movq %rsp, %rdi
    addq $24, %rbx
    movq (%rsp, %rbx), %rsi
    movq %r8, %rdx
    call catnmem

    movq %rbx, %rcx
    subq $8, %rcx

    movq %rbx, %r10
    subq $16, %r10

    movq (%rsp, %rcx,), %rcx
    movq (%rsp, %r10,), %r10

    sys_execve %rsp, %rcx, %r10
    testl %eax, %eax
    jz __sysh_execvp_ret_ignore_stack_restore

    subq $24, %rbx
    addq %rbx, %rsp # restore stack

    popq %rdx
    addq $1, %rdx
    movq %rdx, %r11
    jmp __sysh_execvp_loop0

__sysh_execvp_finish:
    popq %rdx
    popq %rsi
    popq %rdi
__sysh_execvp_ret_ignore_stack_restore:
    ret

