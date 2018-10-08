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
    sys_execve %r8, $0, $0
