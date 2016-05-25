global start_long_mode

extern stack_end

section .text
bits 64

start_long_mode:
    ; Set up the stack
    ; This will write over the previous stack from the 32-bit section, which we
    ;  won't need anymore anyways
    mov rsp, stack_end

    ; Print a hello world
    push 2
    push hello_world_msg
    call asm_print
    add esp, 16

    ; Print a hello again
    push 82
    push hello_again_msg
    call asm_print
    add esp, 16

    ; Show that the kernel has returned, this should be unreachable
    mov rax, 0x4f724f204f534f4f
    mov [0xb8000], rax
    mov rax, 0x4f724f754f744f65
    mov [0xb8008], rax
    mov rax, 0x4f214f644f654f6e
    mov [0xb8010], rax

    hlt

asm_print:
    ; Callee responsibilities
    push rbp        ; Store caller's stack frame
    mov rbp, rsp    ; Make the new stack frame equal the current stack pointer

    ; Get the position on screen we need to print at and multiply it by 2
    mov rbx, [rbp+24]
    mov rax, 2
    mul rbx
    mov rbx, rax

    ; Get the text we need to print
    mov rdx, [rbp+16]

    ; Perform the actual print loop
    mov rcx, 0 ; null the loop counter
    .asm_print_loop:
        ; Write the character to the target location
        mov ah, 0x02
        mov al, [rdx + rcx]
        mov word [0xb8000 + rbx + rcx*2], ax

        ; Loop check
        inc rcx                     ; Increment the loop counter
        cmp byte [rdx + rcx], 0x0   ; Check if the new character is null
        jne .asm_print_loop         ; If it isn't, continue

    ; Callee responsibilities
    mov rsp, rbp    ; Remove all local pushes
    pop rbp         ; Restore caller's stack frame
    ret


section .rodata

hello_world_msg:
    db "Hello, World!",0

hello_again_msg:
    db "Hello, Again!",0
