# Conversor_Base64
Exercício em Assembly que visa desenvolver um código que codifica 3 bytes para a Base64, além de decodificá-los. Também foi implementado um código em C++ que servirá como interface com o usuário, além de realizar algumas tarefas.

<div align="center">
<img src="https://user-images.githubusercontent.com/90197643/190692276-4dfd8b6c-bca6-4664-a201-e9f4e4ebc75b.PNG" width="700px" />
</div>  

<div align="center">
<img src="https://user-images.githubusercontent.com/90197643/190692376-50d646c1-d589-417d-8e5b-686581cc329d.PNG" width="700px" />
</div>  

# Integrantes do grupo2

 - Eduardo Marques dos Reis - 190012358
 - Gabriel Ritter Domingues dos Santos - 190067543
 - João Paulo Marcondes D' Oliveira - 170069923 
 - João Pedro de Oliveira Silva - 190057807
 - Jonatas Gomes Barbosa da Silva - 170059847
 - Tatiana Franco Pereira - 180131206 

# Como instalar o NASM no Windows
No prompt de comando, digite:
```
winget install nasm -i
```

Adicione-o ao Caminho
```
setx Path "%Path%;C:\Program Files\NASM\"
```

Reinicie o prompt de comando e verifique
```
nasm --version
```
# Como compilar 

No terminal, digite:
```
.\compile
```

Ou se preferir: 
```
nasm -f coff base64.asm
g++ c_base64.cpp base64.o -o saida
```

# Como executar

No terminal, digite:
```
.\rodar
```

Para codificar um arquivo em específico, basta digitar:
```
.\saida.exe --encode -i <caminho_para_arquivo_de_entrada> -o <caminho_para_arquivo_de_saída>
```

Para decodificar um arquivo em específico, basta digitar:
```
.\saida.exe --decode -i <caminho_para_arquivo_de_entrada> -o <caminho_para_arquivo_de_saída>
```

# Atividades de cada membro do grupo

### Parte de codificação em Assembly
- João Pedro de Oliveira Silva 
- Tatiana Franco Pereira 

### Parte de decodificação em Assembly
- Jonatas Gomes Barbosa da Silva 
- Gabriel Ritter Domingues dos Santos

### Interface em C++
- João Paulo Marcondes D' Oliveira 
- Eduardo Marques dos Reis