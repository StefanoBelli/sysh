.include "macros.S"

.extern bzeromem
.extern lenstr

.global builtin_cd
.global builtin_cwd

.text
builtin_cd:
builtin_cwd:
    subq $4096, %rsp
    
    movq %rsp, %rdi
    movq $4096, %rsi
    call bzeromem

    sys_getcwd %rsp, $4096

    movq %rsp, %rdi
    addq %rax, %rdi
    movb $10, %dl
    movb %dl, (%rdi)
    addq $1, %rax

    xchgq %rax, %r14
    sys_write_stdout %rsp, %r14
    addq $4096, %rsp

    ret
