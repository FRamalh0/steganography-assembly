# 📦 Steganography 📦

Hide/Recover a message within an image, made with Assembly.

<p align="center"><img src="https://i.imgur.com/PLAOtMB.png" width="400" height="400" alt="Steganography logic"></p>

## 🧰 How it works

Bitmap files (BMP) are image files where the exact value of each pixel is represented explicitly. The structure of this file is divided in two parts: header (blue) and pixel section (orange). 

<p align="center"><img src="https://i.imgur.com/EFrdH4Q.png" width="400" height="400" alt="BMP file structure"></p>

This script is using the ARGB32 specification. Thus, each pixel is composed by bytes 0x0000FFFF is a red pixel with no transparency, 0x00FF00FF is green, 0xFF0000FF is blue, 0x00FFFFFF is yellow.
Each pixel contains 3 bytes of colors (excluding the byte for alpha channel), it is possible to save 3 bits of the message for each pixel of the image. Using this model, if an image with NxN pixels, it can contains, at maximum, (N^2 x 3)/8 caracters.

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
