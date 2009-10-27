#! /bin/bash

ENOENTORNO=14

# Necesario para el correcto funcionamiento de glog
export LOGDIR=$repLOGDIR

# Funcion para imprimir por consola y al log
# Uso: imprimir mensaje [tipo]
imprimir() {
    echo $1
    glog "reporte" $2 "$1"
}

# Funcion para contar las instancias de un proceso dado su nombre
# Uso: contar_instancias proceso
# Almacena la cantidad contada en CANTINST
contar_instancias() {
    if [ -z $1 ]; then
        return
    fi
    
    # De los procesos existentes, se cuentan las instancias del buscado
    CANTINST=$(ps -e | grep "$1" | wc -l)
    # Debe restarse uno porque el subshell abierto incrementa la cantidad de instancias
    if [ "$1" = reporte ]; then (( CANTINST -= 1 )); fi
}

if [ ! $ENTORNO_INICIALIZADO ]; then
    echo "Reporte: Entorno no inicializado"
    exit $ENOENTORNO
fi

# Solo se permite una instancia activa de este script.
contar_instancias reporte
if [ $CANTINST -gt 1 ]; then 
    imprimir "Reporte ya esta corriendo" W
    exit 0
fi

# Inicia el script Perl de reporte.
reporte.pl
