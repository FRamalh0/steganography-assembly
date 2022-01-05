# 📦 Steganography 📦

Hide/Recover a message within an image, made with Assembly.

## 🧰 How it works

<p align="center"><img src="https://i.imgur.com/PLAOtMB.png" width="400" height="400" alt="Steganography logic"></p>

## 🚀 How to execute it

This code was only tested in a Linux environment (Ubuntu in a Virtual Box).
You need to install all dependencies, like 'nasm', if your system doesn't have them.

Requirements: The image file must be in BMP format and the message file must be in TXT format.

```
1. Compile all the files:
	nasm -F dwarf -f elf64 library.asm
	nasm -F dwarf -f elf64 recover.asm
	nasm -F dwarf -f elf64 hide.asm

	ld -o recover recover.o library.o
	ld -o hide hide.o library.o


2. To hide the message, run:
	./hide <path-to-the-txt-file> <path-to-the-BMP-image> <path-to-the-output>

3. To recover the message, run:
	./recover <path-to-the-BMP-image>
```

In this repository, the test folder contains some images to test this script.
