.extern main

.global _start
.text
_start:
    call main

    xorq %rdi, %rdi
    xchgl %eax, %edi
    movq $60, %rax
    syscall
