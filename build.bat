@echo off

mkdir bin

@echo on
nasm -f bin -w-other -o bin\main.bin main.nasm
nasm -f bin -o bin\loader.bin loader.nasm

@echo off
echo.
copy /b bin\loader.bin+bin\main.bin bin\out.img