nasm -f elf64 multiboot_header.asm
nasm -f elf64 boot.asm
ld --nmagic --output=kernel.bin --script=linker.ld multiboot_header.o boot.o
cp kernel.bin isofiles/boot/
grub-mkrescue -o os.iso isofiles
qemu-system-x86_64 -cdrom os.iso
