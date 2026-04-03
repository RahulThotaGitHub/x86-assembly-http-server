# x86 HTTP Server (Assembly)

## Features
- Handles GET & POST requests
- Uses Linux syscalls (socket, bind, listen, accept)
- Process-based concurrency using fork()

## How to Run (I ran in linux terminal)
as get_post.s -o get_post.o

ld get_post.o  -o get_post
#Thus creating an executable file get_post

## Notes
Built as part of systems-level challenges [CTF platforms]
