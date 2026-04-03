.intel_syntax noprefix
.global _start

.section .bss
buffer: .space 512
url: .space 128
buffer1: .space 16385
string: .space 256

.section .data
response:
    .ascii "HTTP/1.0 200 OK\r\n\r\n"
response_len = . - response

.section .text
_start:
    # socket syscall
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    xor rdx, rdx
    syscall
    mov rbx, rax

    # bind socket to port 80
    sub rsp, 16
    mov word ptr [rsp], 2
    mov ax, 80
    xchg al, ah
    mov word ptr [rsp+2], ax
    mov dword ptr [rsp+4], 0
    mov qword ptr [rsp+8], 0

    mov rax, 49
    mov rdi, rbx
    mov rsi, rsp
    mov rdx, 16
    syscall

    # listen
    mov rax, 50
    mov rdi, rbx
    mov rsi, 0
    syscall

loop_start:
    # accept
    mov rax, 43
    mov rdi, rbx
    mov rsi, 0
    mov rdx, 0
    syscall
    mov r12, rax    # save client fd

    # fork child and parent
    mov rax, 57
    syscall

    cmp rax, 0
    jne fork

    mov rax, 3
    mov rdi, rbx
    syscall

    # read request
    mov rax, 0
    mov rdi, r12
    lea rsi, [buffer]
    mov rdx, 512
    syscall
    mov r15, rax

    lea rsi, [buffer]
    mov al, byte ptr [rsi]
    mov r9b, al

find_space:
    mov al, byte ptr [rsi]
    cmp al, ' '
    je space_found
    inc rsi
    jmp find_space

space_found:
    inc rsi

    lea rdi, [url]

copy_content:
    mov al, byte ptr [rsi]
    cmp al, ' '
    je done_copy
    mov byte ptr [rdi], al
    inc rdi
    inc rsi
    jmp copy_content

done_copy:
    mov byte ptr [rdi], 0

    cmp r9, 'G'
    je get_1

    lea rdx, [string]
    mov r10, 22

str:
    inc rsi
    inc r10
    mov al, byte ptr [rsi]
    cmp al, '\r'
    jne str
    inc rsi
    inc r10
    mov al, byte ptr [rsi]
    cmp al, '\n'
    jne str
    inc rsi
    inc r10
    mov al, byte ptr [rsi]
    cmp al, '\r'
    jne str
    inc rsi
    inc r10
    mov al, byte ptr [rsi]
    cmp al, '\n'
    jne str

    sub r15, r10
    mov r8, r15
    inc rsi

copy_str:
    mov al, byte ptr [rsi]
    mov byte ptr [rdx], al
    inc rdx
    inc rsi
    dec r8
    cmp r8, 0
    je done_str
    jmp copy_str

done_str:
    mov byte ptr [rdx], 0

    #open
    mov rax, 2
    lea rdi, [url]
    mov rsi, 65
    mov rdx, 511
    syscall
    mov r14, rax

    cmp r9, 'P'
    je post_0

#GET
get_1:
    #open
    mov rax, 2
    lea rdi, [url]
    mov rsi, 0
    syscall
    mov r8, rax

    #read
    mov rax, 0
    mov rdi, r8
    lea rsi, [buffer1]
    mov rdx, 16385
    syscall
    mov r15, rax

    jmp get_0

#POST
post_0:
    #write
    mov rax, 1
    mov rdi, r14
    lea rsi, [string]
    mov rdx, r15
    syscall

#POST
get_0:
    #close
    mov rax, 3
    mov rdi, r14
    syscall

    mov rax, 3
    mov rdi, r8
    syscall

    # write response
    mov rax, 1
    mov rdi, r12
    lea rsi, [response]
    mov rdx, response_len
    syscall

    cmp r9, 'P'
    je close

#GET
    #write file back
    mov rax, 1
    mov rdi, r12
    lea rsi, [buffer1]
    mov rdi, r12
    lea rsi, [buffer1]
    mov rdx, r15
    syscall

#GET

close:
    #close
    mov rax, 3
    mov rdi, r12
    #syscall

    	jmp exit

	#fork
	fork:
	mov rax, 3
	mov rdi, r12
	syscall

	cmp r9, 'G'
	jne here
#GET

	mov rax, 39
	syscall

#GET
here:
	jmp loop_start

exit:
    # exit
    mov rax, 60
    xor rdi, rdi
    syscall
