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

.macro sys_wait4_pidonly pid
    movq $61, %rax
    movq \pid, %rdi
    xorq %rsi, %rsi
    xorq %rdx, %rdx
    xorq %r10, %r10
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
