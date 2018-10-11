.include "macros.S"

.extern lenstr
.extern split_ws_reverse

.data
execve_failed: .asciz "execve failed\n"
childproc_pid: .long 0
segv_received: .asciz "sysh: segmentation fault\n"

.global childproc_pid
.global sayexec
.text
sayexec:
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
    movl 24(%rsp), %eax # grazie riccardo per il suggerimento sull'offset
    addq $128, %rsp

    cmp $11, %eax
    jne __sayexec_finish

__sayexec_child_segv:
    sys_write_stderr $segv_received, $25

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

    sys_execve %r8, %r14, $0
    
    testq %rax, %rax
    jnz __sayexec_childproc_execve_failed
    jz __sayexec_childproc_finish

__sayexec_childproc_execve_failed:
    sys_write_stderr $execve_failed, $14
    sys_exit $2

__sayexec_childproc_finish:

