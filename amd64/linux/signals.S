.include "macros.S"

.extern childproc_pid

.global __INT_handler
.global install_sighandler

.text
install_sighandler:
    subq $152, %rsp

    movq $469762052, %rax # SA_ONSTACK | SA_SIGINFO | SA_RESTORER | SA_RESTART

    movq $__restorer, 16(%rsp)
    movq %rax, 8(%rsp)
    movq %rsi, (%rsp)
    
    sys_rt_sigaction %rdi, %rsp
    addq $152, %rsp

    retq

__INT_handler:
    retq

__restorer: 
    movq $15, %rax
    syscall
