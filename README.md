# sysh
A weird assembly coded shell

 * no dependencies

 * lightweight executable

 * sometimes bad code ahead

~~~
 $ cd amd64/linux
 $ make
~~~

~~~
 $ ldd sysh
    not a dynamic executable
 $ ls -lah sysh
 -rwxr-xr-x 1 ssynx ssynx 13K 14 ott 11.47 sysh*
~~~

### execute commands

if sysh matches a builtin, the builtin code is executed

otherwise we'll make a syscall to run whatever you type! :)

"execve failed" means that the syscall (SYS_execve) failed, (file not found)

this does not consider the PATH environmental variable, so you'll have to write the full path for
the executable (/bin/ls, /usr/bin/clear, ...).

envctl may be used to get value of an environmental variable and/or unset it.

use env to set a variable (even if sysh_setenv is implemented, see code for more details *env.S*)

## reading status codes

By supporting wait4 system call, we're able to read programs' exit code, to do
so, we rely on the same variable used to store result codes of builtin
operations.

~~~ 
$ sysh_getstatus 
MS32b 
LS32b 
~~~

returns status variable (most significant 32 bits and less significant 32 bits)

### status code bits layout

~~~
b_64...b35 b_34 b_33 b_32 b_31...b_00
---------- ---- ---- ---- -----------
unused     ^^^^ ^^^^ ^^^^ rescode
           |    |    |
           |    | signaled bit
           | coredump bit
       stopped bit
~~~

#### cases

 * A builtin set status variable
   * MS32b is zeroed 
   * LS32b is set to builtin result code
 * Child process status changed and ```sayexec_handle_childstatus``` has set status variable
   * EXITED (e.g. child process called exit()) 
     * MS32b is zeroed 
     * LS32b is set to process exit code 
   * SIGNALED (e.g. CTRL+C, SIGINT) 
     * MS32b is 1 
     * LS32b is set to signo that terminated child 
   * COREDUMPED (e.g. SIGABRT is delivered to child)
     * MS32b is 3 
     * LS32b is set to signo that terminated child and caused process to dump core 
   * STOPPED (e.g. SIGSTOP, SIGTSTP is delivered to child) 
     * MS32b is 4 
     * LS32b is set to signo that stopped child 
   * WAIT4UNKNOWN (wait4 status cannot be "decoded") 
     * MS32b is 7 
     * LS32b is undefined

#### notes

calling sysh_getstatus won't affect status code.

status code will not be changed until ```msysh_internal_setstatus``` is expanded (some move instrs). T

if MS32b is zero, it is user responsibility to remember if the last operation
who might have affected the status code was sysh builtin code or a child
process' exit code
