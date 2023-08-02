.include "macros.S"

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

__restorer: 
	sys_rt_sigreturn
