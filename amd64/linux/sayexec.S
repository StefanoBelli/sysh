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
# ???
    pushq $0
    pushq %r8
    leaq (%rsp), %r14

    sys_execve %r8, %r14, $0
    sys_exit $0
