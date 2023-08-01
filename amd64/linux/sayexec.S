.include "macros.S"
.include "proclimits.S"

.extern lenstr
.extern split_ws_reverse
.extern sysh_execvp

.data
execve_failed: .asciz "execve failed\n"
stopped: .asciz "stopped\n"
signaled: .asciz "signaled\n"
coredumped: .asciz "coredumped\n"
wait4_unknown: .asciz "wait4 unknown\n"

.global sayexec
.text
sayexec_handle_childstatus:
	xorq %rsi, %rsi
	movl %edi, %esi

# WIFEXITED
	andl $0x7f, %edi
	testl %edi, %edi
	jz __sayexec_handle_childstatus_exited

# WIFSIGNALED
	xchgl %eax, %edi
	addb $1, %al
	sarb $1, %al
	cmpb $0, %al
	xchgl %edi, %eax 
	movl %esi, %edi
	jg __sayexec_handle_childstatus_signaled

# WIFSTOPPED
	andl $0xff, %edi
	cmpl $0x7f, %edi
	movq $0xdeadbeefdeadbeef, %rdi
	jne __sayexec_handle_childstatus_failure
	andl $0xff00, %esi
	shrl $8, %esi
	# esi has stop signo
	movq $4, %rcx
	shlq $32, %rcx
	orq %rsi, %rcx
	msysh_internal_setstatus %rcx

	sys_write_stderr $stopped, $8

	jmp __sayexec_handle_childstatus_finish

__sayexec_handle_childstatus_exited:
	andl $0xff00, %esi
	shrl $8, %esi
	# esi has child exit code
	xorq %rcx, %rcx
	orq %rsi, %rcx
	msysh_internal_setstatus %rcx

	jmp __sayexec_handle_childstatus_finish

__sayexec_handle_childstatus_signaled:
	andl $0x80, %edi
	testl %edi, %edi
	jnz __sayexec_handle_childstatus_coredumped
	andl $0x7f, %esi
	# esi has signo that terminated child
	movq $1, %rcx
	shlq $32, %rcx
	orq %rsi, %rcx
	msysh_internal_setstatus %rcx

	cmpl $2, %esi
	je __sayexec_handle_childstatus_finish

	sys_write_stderr $signaled, $9

	jmp __sayexec_handle_childstatus_finish

__sayexec_handle_childstatus_coredumped:
	andl $0x7f, %esi
	# esi has signo that terminated child + trig coredump
	movq $3, %rcx
	shlq $32, %rcx
	orq %rsi, %rcx
	msysh_internal_setstatus %rcx

	sys_write_stderr $coredumped, $11

__sayexec_handle_childstatus_finish:
	xorq %rdi, %rdi
__sayexec_handle_childstatus_failure:
	retq

sayexec:
    xchgq %r11, %rdx
    sys_fork
    xchgq %r8, %r10

    testl %eax, %eax
    jz __sayexec_childproc

    xchgq %rax, %rbx

    subq $148, %rsp
    sys_wait4 %ebx, (%rsp), $2, 4(%rsp) # WUNTRACED
    movl (%rsp), %edi
    addq $148, %rsp
    callq sayexec_handle_childstatus
    testq %rdi, %rdi
    jz __sayexec_finish

    sys_write_stderr $wait4_unknown, $14

    movq $7, %rcx
    shlq $32, %rcx
    msysh_internal_setstatus %rcx
__sayexec_finish:
    ret

__sayexec_childproc:
    pushq $0

    testq %rdx, %rdx
    jz __sayexec_childproc_finalize

    movq %rdx, %rdi
    call lenstr

    movq %rdx, %rdi
    movq %rdx, %rsi
    addq %rax, %rsi
    
__sayexec_childproc_pushargs:
    call split_ws_reverse
    cmpq %rax, %rdi
    je __sayexec_childproc_push_last_arg

    movb $0, (%rax)
    addq $1, %rax
    
    movb (%rax), %bl
    testb %bl, %bl
    jz __sayexec_childproc_prepare_jumpback
    
    pushq %rax

__sayexec_childproc_prepare_jumpback:
    subq $1, %rax
    movq %rax, %rsi
    jmp __sayexec_childproc_pushargs

__sayexec_childproc_push_last_arg:
    pushq %rax

__sayexec_childproc_finalize:
    pushq %r8
    leaq (%rsp), %r14

    movq $PROC_LIMIT_NOFILE, %rdi
    callq sysh_proclimit

    movq %rax, %rcx
__sayexec_childproc_closefds:
    movq %rcx, %rsi
    sys_close %rcx
    movq %rsi, %rcx

    subq $1, %rcx
    cmpq $2, %rcx
    ja __sayexec_childproc_closefds

    movq %r8, %rdi
    movq %r14, %rsi
    movq %r13, %rdx
    call sysh_execvp

    testq %rax, %rax
    jnz __sayexec_childproc_execve_failed
    jz __sayexec_childproc_finish

__sayexec_childproc_execve_failed:
    sys_write_stderr $execve_failed, $14
    sys_exit $2

__sayexec_childproc_finish:

