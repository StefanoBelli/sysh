.extern main

.global _start
.text
_start:
    xorq %rdi, %rdi

    movl (%rsp), %edi    # direct value (argc)
    movq 8(%rsp), %rsi       
    leaq 40(%rsi), %rdx

    call main            # int __eax__  main(int __edi__,
	                 #                   char_ptr __rsi__, 
	                 #                   char_ptr __rdx__)

    xorq %rdi, %rdi
    xchgl %eax, %edi
    movq $60, %rax
    syscall
