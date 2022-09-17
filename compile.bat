nasm -f coff base64.asm
g++ c_base64.cpp base64.o -o saida
.\saida.exe