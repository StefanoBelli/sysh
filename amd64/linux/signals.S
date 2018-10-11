.include "macros.S"

.extern childproc_pid

.global __INT_handler
.global install_sighandler

.text
install_sighandler:
    subq $152, %rsp

    movq $201326596, %rax # SA_ONSTACK | SA_SIGINFO | SA_RESTORER

    movq $__restorer, 16(%rsp)
    movq %rax, 8(%rsp)
    movq %rsi, (%rsp)
    
    sys_rt_sigaction %rdi, %rsp
    addq $152, %rsp

    retq

__INT_handler:
    pushq $0xA
    sys_write_stdout %rsp, $1
    popq %rax
    
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
