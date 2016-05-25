global stack_end

section .bss

stack_begin:
    resb 4096   ; Reserve 4 KiB stack space
stack_end:
