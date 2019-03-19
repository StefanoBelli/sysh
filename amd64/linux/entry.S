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
    pushq %rdi
    pushq %rsi

    addq $8, %rdx
    movq %rdx, %rbx # rbx : envp

    xorq %rcx, %rcx
__entry_setup_len_env:
    addq $1, %rcx
    addq $8, %rdx
    
    movq (%rdx), %rax
    testq %rax, %rax
    jnz __entry_setup_len_env

    movq %rcx, %rax
    movq $8, %rdx
    mulq %rdx

    pushq %rbx

    movq %rax, %rdi
    callq sysh_smalloc

    testq %rax, %rax
    popq %rbx # oldenv
    jz __exit

    movq %rax, %r12 #newenv
    pushq %rax

 __entry_setup_copy_env:
    movq %rbx, %r13 # preserve oldenv

    movq (%rbx), %rdi
    callq lenstr

    addq $1, %rax
    movq %rax, %r14 # r14 --> envsize

    movq %r14, %rdi
    callq sysh_smalloc

    testq %rax, %rax
    jz __exit

    movq %rax, (%r12) # copy address to newenv
    
    movq (%r13), %rdi
    movq %rax, %rsi
    movq %r14, %rdx
    callq cpynmem

    movq %r13, %rbx # oldenv

    addq $8, %r12
    addq $8, %rbx
    movq (%rbx), %rax
    testq %rax, %rax
    jnz __entry_setup_copy_env

    popq %rdx
    popq %rsi
    popq %rdi


    # everything is ready! finally call main()
    call main   # int __eax__  main(int __edi__,
	            #                   char_ptr __rsi__, 
                #                   char_ptr __rdx__)

__exit:
    xorq %rdi, %rdi
    xchgl %eax, %edi
    movq $60, %rax
    syscall
