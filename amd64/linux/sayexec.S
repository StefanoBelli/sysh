.include "macros.S"
.include "proclimits.S"

.extern lenstr
.extern split_ws_reverse
.extern sysh_execvp

.data
execve_failed: .asciz "execve failed\n"
childproc_pid: .long 0
segv_received: .asciz "sysh: segmentation fault\n"

.global childproc_pid
.global sayexec
.text
sayexec:
    msysh_internal_setstatus $0

    xchgq %r11, %rdx
    sys_fork
    xchgq %r8, %r10
    testl %eax, %eax
    jz __sayexec_childproc
    movq $childproc_pid, %rcx
    movl %eax, (%rcx)
    xchgq %rax, %rbx
    
    subq $128, %rsp
    sys_waitid %rbx, %rsp
    movl 24(%rsp), %ebx # return value
    msysh_internal_setstatus %rbx
    movl 8(%rsp), %ebx # why it terminated
    addq $128, %rsp

# check if it is segv
    cmpl $3, %ebx
    jne __sayexec_finish

__sayexec_child_segv:
    sys_write_stderr $segv_received, $25
    msysh_internal_setstatus $11

__sayexec_finish:
    movq $childproc_pid, %rcx
    movl $0, (%rcx)
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

