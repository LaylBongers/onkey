; Externally available labels
global start

section .text
bits 32

start:
    ;; Set up the Page Table and enable Long Mode

    ; Point the first p4_table entry to the first p3_table entry
    mov eax, p3_table
    or eax, 0b11 ; write, read
    mov dword [p4_table + 0], eax

    ; Point the first p3_table entry to the first p2_table entry
    mov eax, p2_table
    or eax, 0b11 ; write, read
    mov dword [p3_table + 0], eax

    ; Point each page p2_table entry to a page
    mov ecx, 0              ; null the loop counter
    .map_p2_table:
        ; Loop body
        mov eax, 0x200000   ; 2MiB
        mul ecx             ; Calculate the location of the page
        or eax, 0b10000011  ; huge pages (2MiB), write, read
        mov [p2_table + ecx * 8], eax   ; Write where this page is pointing to

        ; Loop check
        inc ecx             ; Increment the loop counter
        cmp ecx, 512        ; Check if the loop counter is at 512 (meaning we have reached 1GiB)
        jne .map_p2_table   ; If we haven't, jump back to the start

    ; Move the p4_table address to the control register that needs to hold it
    mov eax, p4_table
    mov cr3, eax ; cr3 needs to be moved to from another register

    ; Enable Physical Address Extension
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Enable Long Mode
    mov ecx, 0xC0000080 ; The Model Specific Register we need to alter
    rdmsr               ; Read it in to eax
    or eax, 1 << 8      ; Enable the Long Mode bit
    wrmsr               ; Write it back

    ; Finally, enable Paging
    mov eax, cr0
    or eax, 1 << 31
    or eax, 1 << 16
    mov cr0, eax

    ; Set up the (unusued but still required) GDT
    lgdt [gdt64.pointer]

    ; Update segment registers
    mov ax, gdt64.data
    mov ss, ax
    mov ds, ax
    mov es, ax

    ; Finally, jump to long mode
    jmp gdt64.code:long_mode_start

bits 64

long_mode_start:
    ; Set the stack pointer
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

    hlt

guard:
    jmp guard

asm_print:
    ; Callee responsibilities
    push rbp        ; store caller's stack frame
    mov rbp, rsp    ; make current stack frame the stack pointer

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
        inc ecx                             ; Increment the loop counter
        cmp byte [rdx + rcx], 0x0   ; Check if the new character is null
        jne .asm_print_loop                 ; If it isn't, continue

    ; Callee responsibilities
    mov rsp, rbp    ; Remove all local pushes
    pop rbp         ; Restore caller's stack frame
    ret


section .bss
align 4096

p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096

stack_begin:
    resb 4096   ; Reserve 4 KiB stack space
stack_end:

section .rodata

gdt64: ; The full (read-only) GDT
    dq 0 ; We aren't actually using the GDT so, zero entry
    .code: equ $ - gdt64
        dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53) ; Code segment
    .data: equ $ - gdt64
        dq (1<<44) | (1<<47) | (1<<41) ; Data segment

        ; In the code and data segments:
        ; 44: ‘descriptor type’: This has to be 1 for code and data segments
        ; 47: ‘present’: This is set to 1 if the entry is valid
        ; 41: ‘read/write’: If this is a code segment, 1 means that it’s readable
        ; 43: ‘executable’: Set to `1 for code segments
        ; 53: ‘64-bit’: If this is a 64-bit GDT, this should be set

    .pointer: ; A data structure that defines where the GDT is
        dw .pointer - gdt64 - 1 ; Length
        dq gdt64                ; Address

hello_world_msg:
    db "Hello, World!",0

hello_again_msg:
    db "Hello, Again!",0

guard_msg:
    db "Leaked into the guard!",0
