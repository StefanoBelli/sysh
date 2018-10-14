.include "macros.S"

.data
not_enough_args: .ascii "not enough arguments provided\n"
could_not_chdir: .ascii "chdir failed\n"
get: .asciz "get"
set: .asciz "set"
unset: .asciz "unset"
invalid_argument: .asciz "invalid argument\n"
envctl_failure: .asciz "envctl failure\n"
newline: .ascii "\n"

.extern bzeromem
.extern lenstr
.extern split_ws
.extern sysh_getenv
.extern sysh_setenv
.extern sysh_unsetenv
.extern cmpstr

.global builtin_cd
.global builtin_cwd
.global builtin_exit
.global builtin_envctl

.text
builtin_exit:
    xorq %rbx, %rbx
    testq %r11, %r11
    setnz %bl
    sys_exit %rbx

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
    
builtin_envctl:
    testq %r11, %r11
    jz __builtin_envctl_fail

    movq %r11, %rax
__builtin_envctl_til_ends_l0:
    movq %rax, %rdx

    movq %rax, %rdi
    callq lenstr

    movq %rdx, %rdi
    movq %rax, %rsi
    callq split_ws

    testq %rax, %rax
    jz __builtin_envctl_til_ends_done

    xorb %cl, %cl
    movb %cl, (%rdi)
    addq $1, %rdi

    jmp __builtin_envctl_til_ends_l0
    
__builtin_envctl_til_ends_done: 
    movq %r11, %rdi
    movq $get, %rsi
    call cmpstr
    testq %rax, %rax
    jnz __builtin_envctl_next_unset

    movq $sysh_getenv, %rax

    jmp __builtin_envctl_perform_request

__builtin_envctl_next_unset:
    movq %r11, %rdi
    movq $unset, %rsi
    call cmpstr
    testq %rax, %rax
    jnz __builtin_envctl_invalid_argument

    movq $sysh_unsetenv, %rax

__builtin_envctl_perform_request:
    pushq %rax

    addq $1, %rdi
    movq %r13, %rsi
    callq *%rax
    movq %rax, %rdx

    testq %rax, %rax
    popq %rax
    jz __builtin_envctl_finish_fail
    jnz __builtin_envctl_finish

__builtin_envctl_fail:
    sys_write_stderr $not_enough_args, $30
    retq

__builtin_envctl_invalid_argument:
    sys_write_stderr $invalid_argument, $17
    retq

__builtin_envctl_finish_fail:
    sys_write_stderr $envctl_failure, $15
    retq

__builtin_envctl_finish:
    movq $sysh_getenv, %rbx
    cmpq %rax, %rbx
    jne __builtin_envctl_finally_ret

    movq %rdx, %rdi
    call lenstr

    movq %rax, %r13
    sys_write_stdout %rdx, %r13
    sys_write_stdout $newline, $1
__builtin_envctl_finally_ret:
    retq
