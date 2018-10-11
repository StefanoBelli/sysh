.include "macros.S"

.extern childproc_pid

.global install_sighandlers
.text
install_sighandlers:
    subq $152, %rsp

    movq $201326596, %rax # SA_ONSTACK | SA_SIGINFO | SA_RESTORER

    movq $__restorer, 16(%rsp)
    movq %rax, 8(%rsp)
    movq $__INT_handler, (%rsp)
    
    sys_rt_sigaction $2, %rsp # SIGINT

    addq $152, %rsp

    retq

__INT_handler:
    movq $childproc_pid, %rbx
    movl (%rbx), %eax
    testl %eax, %eax
    jz __INT_handler_end

    xchgq %rax, %rcx
    sys_kill %rcx, $2

__INT_handler_end:
    retq
    
__restorer: 
    movq $15, %rax
    syscall
