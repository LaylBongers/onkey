global start


section .text
bits 32
start:
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
        jne .map_p2_table   ; if we haven't, jump back to the start

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

    ; And finally, enable Paging
    mov eax, cr0
    or eax, 1 << 31
    or eax, 1 << 16
    mov cr0, eax

    ; Print a message
    mov word [0xb80a0], 0x0248 ; H
    mov word [0xb80a2], 0x0265 ; e
    mov word [0xb80a4], 0x026c ; l
    mov word [0xb80a6], 0x026c ; l
    mov word [0xb80a8], 0x026f ; o
    mov word [0xb80aa], 0x022c ; ,
    mov word [0xb80ac], 0x0220 ;
    mov word [0xb80ae], 0x0277 ; w
    mov word [0xb80b0], 0x026f ; o
    mov word [0xb80b2], 0x0272 ; r
    mov word [0xb80b4], 0x026c ; l
    mov word [0xb80b6], 0x0264 ; d
    mov word [0xb80b8], 0x0221 ; !
    hlt


section .bss

align 4096

p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096
