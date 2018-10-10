	.file	"sigproc.c"
	.text
	.globl	handler
	.type	handler, @function
handler:
.LFB0:
	.cfi_startproc
	movl	%edi, -4(%rsp)
	nop
	ret
	.cfi_endproc
.LFE0:
	.size	handler, .-handler
	.globl	main
	.type	main, @function
main:
.LFB1:
	.cfi_startproc
	subq	$168, %rsp
	.cfi_def_cfa_offset 176
	movq	%fs:40, %rax
	movq	%rax, 152(%rsp)
	xorl	%eax, %eax
	leaq	handler(%rip), %rax
	movq	%rax, (%rsp)
	movl	$4, 136(%rsp)
	movq	%rsp, %rax
	movl	$0, %edx
	movq	%rax, %rsi
	movl	$2, %edi
	call	sigaction@PLT
	movl	$0, %eax
	movq	152(%rsp), %rcx
	xorq	%fs:40, %rcx
	je	.L4
	call	__stack_chk_fail@PLT
.L4:
	addq	$168, %rsp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE1:
	.size	main, .-main
	.ident	"GCC: (GNU) 8.2.1 20180831"
	.section	.note.GNU-stack,"",@progbits
