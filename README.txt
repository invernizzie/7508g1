
Instalacion
------------

Pasos de instalacion:

1- Crear en el directorio corriente un subdirectorio grupo01.

$ mkdir grupo01

2- Copiar el archivo *.tgz en el directorio del paso anterior.

$ cp <RUTA programa.tgz> ./grupo01

donde <RUTA programa.tgz> es la direccion donde se encuentra el progama.  

3- Extraer los archivos del programa.tgz.

$ tar -xzvf programa.tgz 

4- Dar permisos de ejecucion al archivo instalar.

$ chmod +x instalar

5- Comenzar la instalacion. Correr el instalador.

$ instalar

6- Seguir los pasos indicados durante la instalacion. Una vez terminado si no
hubo ningun error, para comenzar a usar el programa hay que posicionarnos en el 
directorio de binarios seteados en la instalacion e iniciar el entorno.
mediante el comando iniciar(inline).

$ cd <RUTA binarios>
$ . iniciar


