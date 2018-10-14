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
