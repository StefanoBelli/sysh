.include "macros.S"

.bss
.lcomm __handler, 152

.extern __main_l0_end
.extern childproc_pid

.global install_sighandlers
.text
install_sighandlers:
    movq $748212304, %rax
    xorq %rbx, %rax

    movq $__handler, %rbx

    movq $__restorer, 16(%rbx)
    movq %rax, 8(%rbx)
    movq $__INT_handler, (%rbx)
    sys_rt_sigaction $2, $__handler

    ret

__INT_handler:
    movq $childproc_pid, %rbx
    movl (%rbx), %eax
     
    testl %eax, %eax
    jz __main_l0_end
    
    xchgq %rax, %rcx
    sys_kill %rcx, $2

    jmp __main_l0_end

__restorer:
