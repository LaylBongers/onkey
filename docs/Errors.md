# Errors

## Early Boot Errors
These errors occur in the early booting stage, during the 32-bit section. These
errors will appear in red at the top left of the screen.

- `ERR: 0` The kernel is being booted through a non-Multiboot compliant bootloader.
- `ERR: 1` The CPU does not support the `cpuid` instruction.
- `ERR: 2` The CPU does not support 64-bit.

## Misc Errors
- `OS returned!` The kernel returned back into assembly, this is an internal error.
