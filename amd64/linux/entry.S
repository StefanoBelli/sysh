.extern main

.global _start
.text
_start:
    xorq %rdi, %rdi

    movl (%rsp), %edi    # direct value (argc)
    movq %rsp, %rsi       
    addq $8, %rsi        # argv
     
    movq %rsp, %rdx
__entry_get_envp_start:
    movq (%rdx), %rax
    testq %rax, %rax
    jz __entry_get_envp_done

    addq $8, %rdx
    jmp __entry_get_envp_start

__entry_get_envp_done:
    addq $8, %rdx        # envp
    
    call main            # int __eax__  main(int __edi__,
	                 #                   char_ptr __rsi__, 
	                 #                   char_ptr __rdx__)

    xorq %rdi, %rdi
    xchgl %eax, %edi
    movq $60, %rax
    syscall
