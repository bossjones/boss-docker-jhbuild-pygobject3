# When to use exec?

`source: `

`exec` replaces the current program in the current process, without forking a new process. It is not something you would use in every script you write, but it comes in handy on occasion. Here are some scenarios I have used it;

1. We want the user to run a specific application program without access to the shell. We could change the sign-in program in /etc/passwd, but maybe we want environment setting to be used from start-up files. So, in (say) .profile, the last statement says something like:

`exec appln-program`

so now there is no shell to go back to. Even if appln-program crashes, the end-user cannot get to a shell, because it is not there - the exec replaced it.

2. We want to use a different shell to the one in /etc/passwd. Stupid as it may seem, some sites do not allow users to alter their sign-in shell. One site I know had everyone start with csh, and everyone just put into their .login (csh start-up file) a call to ksh. While that worked, it left a stray csh process running, and the logout was two stage which could get confusing. So we changed it to exec ksh which just replaced the c-shell program with the korn shell, and made everything simpler (there are other issues with this, such as the fact that the ksh is not a login-shell).

3. Just to save processes. If we call prog1 -> prog2 -> prog3 -> prog4 etc. and never go back, then make each call an exec. It saves resources (not much, admittedly, unless repeated) and makes shutdown simplier.
You have obviously seen exec used somewhere, perhaps if you showed the code that's bugging you we could justify its use.

Edit: I realised that my answer above is incomplete. There are two uses of exec in shells like ksh and bash - used for opening file descriptors. Here are some examples:

```
exec 3< thisfile          # open "thisfile" for reading on file descriptor 3
exec 4> thatfile          # open "thatfile" for writing on file descriptor 4
exec 8<> tother           # open "tother" for reading and writing on fd 8
exec 6>> other            # open "other" for appending on file descriptor 6
exec 5<&0                 # copy read file descriptor 0 onto file descriptor 5
exec 7>&4                 # copy write file descriptor 4 onto 7
exec 3<&-                 # close the read file descriptor 3
exec 6>&-                 # close the write file descriptor 6
```

Note that spacing is very important here. If you place a space between the fd number and the redirection symbol then exec reverts to the original meaning:


`exec 3 < thisfile       # oops, overwrite the current program with command "3"`

There are several ways you can use these, on ksh use read -u or print -u, on bash, for example:

```
read <&3
echo stuff >&4
```