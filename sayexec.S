.include "macros.S"

.global sayexec
.text
sayexec:
    sys_fork
    testl %eax, %eax
    jz __sayexec_childproc
    sys_wait4_pidonly %rax

    ret

__sayexec_childproc:
    sys_exit $0
