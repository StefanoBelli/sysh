.include "macros.S"

.data
sz_sysh_banner: .string "sysh version 0.0.0\n"
sz_sysh_builtin_exit: .string "exit\n"

.extern handle_input
.extern bzeromem
.extern cmpstr
.extern dellc

.global main

.text
main:
    sys_write_stdout $sz_sysh_banner, $19

    xorw %bx, %bx
    movb $0x20, %bh
    sys_getuid
    setz %bl
    addb $0x23, %bl

    subq $2048, %rsp
    pushq %rbp
    movq %rsp, %rbp
    pushw %bx

__main_l0:
    sys_write_stdout %rsp, $2

    movq %rbp, %rdi
    movq $2048, %rsi
    call bzeromem

    sys_read_stdin %rbp, $2048

    movq %rbp, %rdi
    movq $sz_sysh_builtin_exit, %rsi
    call cmpstr

    testl %eax, %eax
    jz __main_finish

    movq %rbp, %rdi
    call dellc
     
    movq %rbp, %rdi
    call handle_input

    jmp __main_l0

__main_finish:
    popw %bx
    popq %rbp
    addq $2048, %rsp

    xorl %eax, %eax
    ret
