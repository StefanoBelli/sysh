.include "macros.S"

.data
sz_sysh_banner: .string "sysh version 0.3.10\n"
last_status_code_operation: .quad 0

.extern install_sighandler
.extern handle_input
.extern bzeromem
.extern cmpstr
.extern erase_newline
.extern erase_trailing_ws

.global main
.global last_status_code_operation

.text

__INT_handler:
__STOP_handler:
__TSTP_handler:
	retq

main:
    pushq %rdx # preserve envp

    movq $__INT_handler, %rsi
    movq $2, %rdi # SIGINT
    callq install_sighandler

    movq $__STOP_handler, %rsi
    movq $19, %rdi # SIGSTOP
    callq install_sighandler

    movq $__TSTP_handler, %rsi
    movq $20, %rdi #SIGTSTP
    callq install_sighandler

    sys_write_stdout $sz_sysh_banner, $20

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
