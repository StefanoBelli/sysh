.extern builtin_cd
.extern builtin_cwd
.extern sayexec
.extern cmpstr
.extern lenstr

.global handle_input
.text
handle_input:
    movq $__builtins, %r9
    movq %rdi, %r10
__handle_input_l0:
    movq (%r9), %r8
    testq %r8, %r8
    jz __handle_input_start_sayexec

    movq %r10, %rdi
    movq %r9, %rsi
    call cmpstr

    pushq %rax

    movq %r9, %rdi
    call lenstr
    addq %rax, %r9
    addq $9, %r9

    popq %rax

    testl %eax, %eax
    jnz __handle_input_l0

__handle_input_start_subr:
    subq $8, %r9
    jmp *(%r9)

__handle_input_start_sayexec:
    addq $8, %r9
    jmp *(%r9)

    # ret

__builtins:
    .asciz "cd"
    .quad builtin_cd

    .asciz "cwd"
    .quad builtin_cwd

    .quad 0
    .quad sayexec
