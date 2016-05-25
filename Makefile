default: run

.PHONY: clean

build/multiboot_header.o: arch/x86_64/multiboot_header.asm
	mkdir -p build
	nasm -f elf64 arch/x86_64/multiboot_header.asm -o build/multiboot_header.o

build/start.o: arch/x86_64/start.asm
	mkdir -p build
	nasm -f elf64 arch/x86_64/start.asm -o build/start.o

build/start_long_mode.o: arch/x86_64/start_long_mode.asm
	mkdir -p build
	nasm -f elf64 arch/x86_64/start_long_mode.asm -o build/start_long_mode.o

build/stack.o: arch/x86_64/stack.asm
	mkdir -p build
	nasm -f elf64 arch/x86_64/stack.asm -o build/stack.o

build/kernel.bin: build/multiboot_header.o build/start.o build/start_long_mode.o arch/x86_64/linker.ld
	ld -n -o build/kernel.bin -T arch/x86_64/linker.ld build/multiboot_header.o build/start.o build/start_long_mode.o build/stack.o

build/os.iso: build/kernel.bin arch/x86_64/grub.cfg
	mkdir -p build/isofiles/boot/grub
	cp arch/x86_64/grub.cfg build/isofiles/boot/grub
	cp build/kernel.bin build/isofiles/boot/
	grub-mkrescue -o build/os.iso build/isofiles

run: build/os.iso
	qemu-system-x86_64 -cdrom build/os.iso

build: build/os.iso

clean:
	rm -rf build
