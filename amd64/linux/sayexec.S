.include "macros.S"
.include "proclimits.S"

.extern lenstr
.extern split_ws_reverse
.extern sysh_execvp

.data
execve_failed: .asciz "execve failed\n"

.global sayexec
.text
sayexec:
    xchgq %r11, %rdx
    sys_fork
    xchgq %r8, %r10

    testl %eax, %eax
    jz __sayexec_childproc

    xchgq %rax, %rbx

    subq $148, %rsp
    sys_wait4 %ebx, (%rsp), $0, 4(%rsp)
    addq $148, %rsp

__sayexec_finish:
    ret

__sayexec_childproc:
    pushq $0

    testq %rdx, %rdx
    jz __sayexec_childproc_finalize

    movq %rdx, %rdi
    call lenstr

    movq %rdx, %rdi
    movq %rdx, %rsi
    addq %rax, %rsi
    
__sayexec_childproc_pushargs:
    call split_ws_reverse
    cmpq %rax, %rdi
    je __sayexec_childproc_push_last_arg

    movb $0, (%rax)
    addq $1, %rax
    
    movb (%rax), %bl
    testb %bl, %bl
    jz __sayexec_childproc_prepare_jumpback
    
    pushq %rax

__sayexec_childproc_prepare_jumpback:
    subq $1, %rax
    movq %rax, %rsi
    jmp __sayexec_childproc_pushargs

__sayexec_childproc_push_last_arg:
    pushq %rax

__sayexec_childproc_finalize:
    pushq %r8
    leaq (%rsp), %r14

    movq $PROC_LIMIT_NOFILE, %rdi
    callq sysh_proclimit

    movq %rax, %rcx
__sayexec_childproc_closefds:
    movq %rcx, %rsi
    sys_close %rcx
    movq %rsi, %rcx

    subq $1, %rcx
    cmpq $2, %rcx
    ja __sayexec_childproc_closefds

    movq %r8, %rdi
    movq %r14, %rsi
    movq %r13, %rdx
    call sysh_execvp

    testq %rax, %rax
    jnz __sayexec_childproc_execve_failed
    jz __sayexec_childproc_finish

__sayexec_childproc_execve_failed:
    sys_write_stderr $execve_failed, $14
    sys_exit $2

__sayexec_childproc_finish:

