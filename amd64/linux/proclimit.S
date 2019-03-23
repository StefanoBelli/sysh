.include "proclimits.S"
.include "macros.S"

.global sysh_proclimit

.text
sysh_proclimit:
    movq %rdi, %r12

    subq $16, %rsp # struct rlimit64
    sys_prlimit64 $0, %r12, $0, %rsp

    movq (%rsp), %rax

    addq $16, %rsp
    retq
