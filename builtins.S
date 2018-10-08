.include "macros.S"

.data
not_enough_args: .ascii "not enough arguments provided\n"
could_not_chdir: .ascii "chdir failed\n"

.extern bzeromem

.global builtin_cd
.global builtin_cwd
.global builtin_exit

.text
builtin_exit:
    sys_exit $0

builtin_cd:
    testq %r11, %r11
    jnz __builtin_cd_chdir
    sys_write_stderr $not_enough_args, $30
    ret
__builtin_cd_chdir:
    sys_chdir %r11
    testq %rax, %rax
    jz __builtin_cd_success
__builtin_cd_fail:
    sys_write_stderr $could_not_chdir, $13
__builtin_cd_success:
    ret

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
