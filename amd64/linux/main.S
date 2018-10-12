.include "macros.S"

.data
sz_sysh_banner: .string "sysh version 0.1.1\n"

.extern install_sighandler
.extern handle_input
.extern bzeromem
.extern cmpstr
.extern erase_newline
.extern erase_trailing_ws
.extern __INT_handler

.global main

.text
main:
    pushq %rdx # preserve envp

    movq $__INT_handler, %rsi
    movq $2, %rdi # SIGINT
    call install_sighandler
    
    sys_write_stdout $sz_sysh_banner, $19

    xorw %bx, %bx
    movb $0x20, %bh
    sys_getuid
    setz %bl
    addb $0x23, %bl

    pushw %bx
    movq %rsp, %rbp

    subq $2048, %rsp

__main_l0:
    sys_write_stdout %rbp, $2
    
    movq %rsp, %rdi
    movq $2048, %rsi
    call bzeromem

    sys_read_stdin %rsp, $2048

    movq %rsp, %rdi
    call erase_newline

    movq %rsp, %rdi
    call erase_trailing_ws

    movq %rsp, %rdi
    call lenstr
    testq %rax, %rax
    jz __main_l0_end

    movq 2(%rbp), %rdx
    movq %rsp, %rdi
    call handle_input

__main_l0_end:
    jmp __main_l0

__main_finish:
    popw %bx
    popq %rdx
    addq $2048, %rsp
    
    xorl %eax, %eax
    ret
