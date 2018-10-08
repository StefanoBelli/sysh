.include "macros.S"


.global sayexec
.text
sayexec:
    sys_fork
    xchgq %r8, %r10
    testl %eax, %eax
    jz __sayexec_childproc
    sys_wait4_pidonly %rax

    ret

__sayexec_childproc:
    pushq %rsp
    movq %rbp, %rsp
    subq $16, %rsp

#todo
    movq %r8, -16(%rbp)
    movq $0, -8(%rbp)
    leaq -16(%rbp), %r14

    sys_execve %r8, %r14, $0
