.macro sys_getuid
    movq $102, %rax
    syscall
.endm

.macro sys_write fd, buf, len
    movq $1, %rax
    movq \fd, %rdi
    movq \buf, %rsi
    movq \len, %rdx
    syscall
.endm

.macro sys_read fd, buf, len
    movq $0, %rax
    movq \fd, %rdi
    movq \buf, %rsi
    movq \len, %rdx
    syscall
.endm

.macro sys_write_stderr buf, len
    sys_write $2, \buf, \len
.endm

.macro sys_write_stdout buf, len
    sys_write $1, \buf, \len
.endm

.macro sys_read_stdin buf, len
    sys_read $0, \buf, \len
.endm

.macro sys_getcwd buf, len
    movq $79, %rax
    movq \buf, %rdi
    movq \len, %rsi
    syscall
.endm

.macro sys_chdir buf
    movq $80, %rax
    movq \buf, %rdi
    syscall
.endm

.macro sys_exit code
    movq $60, %rax
    movq \code, %rdi
    syscall
.endm

.macro sys_waitid pid, infop
    movq $247, %rax
    movq $1, %rdi
    movq \pid, %rsi
    movq $6,%r10
    movq \infop, %rdx
    syscall
.endm

.macro sys_fork
    movq $57, %rax
    syscall
.endm
    
.macro sys_execve filename, argv, envp
    movq $59, %rax
    movq \filename, %rdi
    movq \argv, %rsi
    movq \envp, %rdx
    syscall
.endm

.macro sys_rt_sigaction sig, sigaction_s
    movq $13, %rax
    movq \sig, %rdi
    movq \sigaction_s, %rsi
    xorq %rdx, %rdx
    movq $8, %r10
    syscall
.endm

.macro sys_kill pid, sig
    movq $62, %rax
    movq \pid, %rdi
    movq \sig, %rsi
    syscall
.endm
