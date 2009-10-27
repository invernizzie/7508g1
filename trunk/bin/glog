#! /bin/bash

MAXLINES=50
ENOARGS=65
ENOENTORNO=14

if [ ! $ENTORNO_INICIALIZADO ]; then
    echo "Glog: Entorno no inicializado"
    exit $ENOENTORNO
fi

if [ $# -lt 2 ]; then
    echo "Glog: Uso: `basename $0` comando tipo_msj=I mensaje"
    #glog glog E "Cantidad de parametros incorrecta"
    exit $ENOARGS
fi

COMANDO=$1

# Funcion para imprimir por consola y al log
imprimir() {
    echo $1
    
    glog $COMANDO $2 "$1"
}

if [ $# -eq 2 ]; then
    MENSAJE=$2
    TIPO_MSJ=I
else 
    MENSAJE=$3
    TIPO_MSJ=$2
fi

if [ $# -gt 3 ]; then
    imprimir "Glog: Se esperaban 2 o 3 parametros y se recibieron $#" W
fi

if [[ $TIPO_MSJ != [IWE] ]] && [ $TIPO_MSJ != SE ]; then
    imprimir "Glog: Tipo de mensaje invalido" W
fi

# Si el directorio de logs no existe lo crea.
if [ ! -e "$LOGDIR" ]; then
    mkdir -p "$LOGDIR"
fi

# Escribe en el archivo log.
LOGFILE="$LOGDIR/$COMANDO.log"
DATE=$(date '+%Y/%m/%d %H:%M:%S')
echo "$DATE-$TIPO_MSJ-$MENSAJE" >> "$LOGFILE"

# Si el archivo se pasa de $MAXLOG se trunca a MAXLINES.
SIZE=$(stat -c %s "$LOGFILE")
# Cuidado! Si MAXLOG esta declarada pero no es un entero, 
# la comparacion falla y el script termina con error
if [ ! -z $MAXLOG ] && [ $SIZE -gt $MAXLOG ]; then
    tail -n $MAXLINES "$LOGFILE" >"$LOGFILE.temp"
    mv -f "$LOGFILE.temp" "$LOGFILE"
fi

# Si se sigue pasando de tamanio, se trunca a cero.
SIZE=$(stat -c %s "$LOGFILE")
if [ ! -z $MAXLOG ] && [ $SIZE -gt $MAXLOG ]; then
    >"$LOGFILE"
fi

exit 0
