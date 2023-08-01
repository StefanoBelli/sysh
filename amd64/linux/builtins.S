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
.extern last_status_code_operation

.global builtin_cd
.global builtin_cwd
.global builtin_exit
.global builtin_envctl
.global builtin_sysh_getstatus
.global builtin_envset

.text
builtin_exit:
    xorq %rbx, %rbx
    testq %r11, %r11
    setnz %bl
    sys_exit %rbx

builtin_cd:
    msysh_internal_setstatus $0
    testq %r11, %r11
    jnz __builtin_cd_chdir
    sys_write_stderr $not_enough_args, $30
    msysh_internal_setstatus $1
    ret
__builtin_cd_chdir:
    sys_chdir %r11
    testq %rax, %rax
    jz __builtin_cd_success
__builtin_cd_fail:
    msysh_internal_setstatus $2
    sys_write_stderr $could_not_chdir, $13
    ret
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
    msysh_internal_setstatus $3
    sys_write_stderr $not_enough_args, $30
    retq

__builtin_envctl_invalid_argument:
    msysh_internal_setstatus $2
    sys_write_stderr $invalid_argument, $17
    retq

__builtin_envctl_finish_fail:
    msysh_internal_setstatus $1
    sys_write_stderr $envctl_failure, $15
    retq

__builtin_envctl_finish:
    pushq %rax
    msysh_internal_setstatus $0
    popq %rax

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
    
builtin_sysh_getstatus:
    pushq %rdi
    pushq %rsi

    subq $11, %rsp

# higher 32 bits
    movq %rsp, %rdi
    movq $11, %rsi
    call bzeromem

    movq $last_status_code_operation, %rax
    movq (%rax), %rdi
    shrq $32, %rdi
    movq %rsp, %rsi
    call unsigned_int32tos_buf

    movq $0xa, 10(%rsp)
    sys_write_stdout %rsp, $11

# lower 32 bits
    movq %rsp, %rdi
    movq $11, %rsi
    call bzeromem

    movq $last_status_code_operation, %rax
    movq (%rax), %rdi
    movq %rsp, %rsi
    call unsigned_int32tos_buf

    movq $0xa, 10(%rsp)
    sys_write_stdout %rsp, $11

# end

    addq $11, %rsp

    popq %rsi
    popq %rdi
    ret
    
builtin_envset:
    movq %r11, %r8

    testq %r11, %r11
    jnz __builtin_envset_proceed

    movq %r13, %rdi
    callq sysh_envcount

    subq $10, %rsp

    movq %rax, %r10

    movq %rsp, %rdi
    movq $10, %rsi
    callq bzeromem

    movq %r10, %rax

    movq %rsp, %rsi
    movq %rax, %rdi
    callq unsigned_int32tos_buf

    sys_write_stdout %rsp, $10
    sys_write_stdout $newline, $1

    addq $10, %rsp

    retq
    
__builtin_envset_proceed:
    movb $'=', %bl
__builtin_envset_get_kvpair_sep:
    movb (%r11), %al
    addq $1, %r11
    cmpb %bl, %al
    jne __builtin_envset_get_kvpair_sep

    movb $' ',%bl
__builtin_envset_getvalue:
    movb (%r11), %al
    addq $1, %r11
    cmpb %bl, %al
    je __builtin_envset_getvalue

    subq $1, %r11

    movq %r11, %r12 #value
    
    movq %r8, %r11
__builtin_envset_getkey:
    movb (%r11), %al
    addq $1, %r11
    cmpb %bl, %al
    je __builtin_envset_getkey

    subq $1, %r11

    movq %r11, %r8

    movb $'=', %cl
__builtin_envset_get_keyend:
    movb (%r11), %al
    addq $1, %r11
    cmpb %cl, %al
    je __builtin_envset_set_keyend
    cmpb %bl, %al
    jne __builtin_envset_get_keyend

__builtin_envset_set_keyend:
    subq $1, %r11
    movb $0, (%r11)

__builtin_envset_setenv:
    movq %r8, %r11

    movq %r13, %rdx
    movq %r12, %rsi
    movq %r11, %rdi
    callq sysh_setenv
    retq
