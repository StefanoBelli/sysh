.include "macros.S"

.extern lenstr
.extern split_ws_reverse

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

    movq (%r11), %r14

    /*
    xchgq %rdx, %rax
    movq %rdi, %rsi
    addq %rdx, %rsi
__sayexec_childproc_l0:
    movq %r11, %rdi
   // call split_ws_reverse

//    movb $0, (%rax)
    addq $1, %rax
    pushq %rax

    subq $1, %rax
    cmpq %rax, %rdi
    movq %rax, %rsi
    jne __sayexec_childproc_l0
*/
    pushq $0
    pushq %r8
    leaq (%rsp), %r14

    sys_execve %r8, %r14, $0
    sys_exit $0
