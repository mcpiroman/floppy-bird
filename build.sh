mkdir -p bin

nasm -f bin -w-other -o bin/main.bin main.nasm
nasm -f bin -o bin/loader.bin loader.nasm

cat bin/loader.bin bin/main.bin > bin/out.img