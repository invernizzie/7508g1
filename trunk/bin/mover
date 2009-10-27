#!/bin/bash

# Codigos de error
ENOARGS=65
ENOFILE=66
ENOENTORNO=14

# Necesario para el correcto funcionamiento de glog
export LOGDIR=$movLOGDIR

# Funcion para imprimir por consola y al log
# Uso: imprimir mensaje [tipo]
imprimir() {
    #echo $1
    
    if [ $USAR_LOG ]; then
        glog "$COMANDO" $2 "$1"
    fi
}

# Funcion para determinar el orden de secuencia
det_sec() {
    SEC=1

    for ARCH in "$DIRDEST/dup/$(basename $DEST)".*
    do
        # Se extrae la secuencia de los duplicados existentes
        TMP=$(expr "$ARCH" : '.*\(\.[0-9]*\)')
        TMP=${TMP:1}

        # Se incrementa en uno el valor actual de la secuencia
        if [ "$TMP" -ge "$SEC" ] &>/dev/null; then
            SEC=$((TMP+1))
        fi
    done
    
    imprimir "Mover: Duplicado de $(basename "$DEST") numero $SEC" I
}

if [ ! $ENTORNO_INICIALIZADO ]; then
    imprimir "Mover: Entorno no inicializado"
    exit $ENOENTORNO
fi

# Se chequean parametros obligatorios
if [ $# -lt 2 -o $# -gt 3 ]; then
    imprimir "Uso: `basename $0` origen destino [comando]" SE
    exit $ENOARGS
fi

if [ $# -eq 3 ]; then
    USAR_LOG=1
    COMANDO=$3
fi

# Si el destino es igual al origen no se debe hacer nada
if [ "$1" = "$2" ]; then
    imprimir "Mover: Archivo de destino igual a archivo de origen" W
    exit $ENOARGS
fi

# Se verifica que el origen exista
if [ ! -e "$1" ]; then
    imprimir "Mover: $1 no es un archivo de origen valido" E
    exit $ENOFILE
fi

DEST="$2"

# Si el destino es un directorio se asume copiar con igual nombre
if [ -e "$2" -a -d "$2" ]; then
    DEST="${2%/}/$(basename "$1")"
fi

# Si no es duplicado se mueve y se termina la ejecucion
if [ ! -e "$DEST" ]; then
    mv "$1" "$DEST"
    if [ $# -eq 3 ]; then
        imprimir "Mover: exitoso de $1 a $DEST" I
    fi
    exit 0

# Si es duplicado se gestiona la secuencia
else
    DIRDEST="$(dirname "$DEST")"

    # Si no existe se crea el directorio de duplicados
    if [ ! -d "$DIRDEST"/dup ]; then
        mkdir "$DIRDEST"/dup 
    fi

    # Se determina el numero de secuencia siguiente
    det_sec
    # Se mueve la version que se queria copiar a /dup
    mv "$1" "$DIRDEST/dup/$(basename "$DEST").$SEC"
fi

exit 0
