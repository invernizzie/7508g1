#! /bin/bash 

ENOENTORNO=14
ENODATADIR=15
ENODIR=16
ENOFORMATO=17

# Necesario para el correcto funcionamiento de glog
export LOGDIR=$detLOGDIR

ERRDESC=( \
[$ENOENTORNO]="Entorno no inicializado" \
[$ENODATADIR]="Directorio de entrada inexistente" \
[$ENODIR]="Directorio inexistente" \
[$ENOFORMATO]="Error de formato" )

PSTAB="$GRUPO/conf/p-s.tab"    # Tabla de Paises y Sistemas
DIROK="$DATADIR/ok"                # Directorio de aceptados
DIRNOK="$DATADIR/nok"              # Directorio de rechazados

# Funcion para imprimir por consola y al log
# Uso: imprimir mensaje [tipo]
imprimir() {
    glog "detectar" $2 "$1"
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
    if [ "$1" = detectar ]; then (( CANTINST -= 1 )); fi
}

# Funcion para leer la tabla de archivos y sistemas
leer_paises_y_sistemas() {
    
    REGISTROS=$(wc -l <"$PSTAB")
    CUENTA=0
    # Se procesa cada linea de la tabla
    {
    while [ $CUENTA -lt $REGISTROS ]
    do
        # Se lee un registro de la tabla
        read LINEA
        # Si la linea esta vacia o comentada se saltea
        if [ ${#LINEA} -lt 1 -o "${LINEA:0:1}" = "#" ]; then
            (( REGISTROS -= 1 ))
            continue
        fi
        
        # Se extrae el codigo de pais
        PAISES[$CUENTA]=$(expr "$LINEA" : '\([^-]*\)')
        # Se extrae el codigo de sistema
        SISTEMAS[$CUENTA]=$(expr "$LINEA" : '[^-]*-[^-]*-\([^-]\)')
        
        (( CUENTA += 1 ))
    done
    } < "$PSTAB"
}

# Funcion para validar los nombres de archivos de entrada
# Uso: validar_nombre archivo
# Formato de nombre de archivo: <pais>-<sistema>-<anio>-<mes>
validar_nombre() {
    if [ -z $1 ]; then
        return
    fi
    
    PAIS=$(expr "$1" : '\([^-]*\)')
    SISTEMA=$(expr "$1" : '[^-]*-\([^-]*\)')
    ANIO=$(expr "$1" : '[^-]*-[^-]*-\([^-]*\)')
    MES=$(expr "$1" : '.*-\(.*\)')

    # Se comprueba la validez del anio
    ANIOACTUAL="$(date +%Y)"
    MESTOPE=12
    if [ "$ANIO" -lt 2000 -o "$ANIO" -gt "$ANIOACTUAL" ]; then
        false
        return
    fi
    # Si el anio es el actual, el mes tope es el actual
    if [ "$ANIO" -eq "$ANIOACTUAL" ]; then
        MESTOPE=$(date +%m)
    fi
    # Se comprueba la validez del mes
    if [ "$MES" -lt 1 -o "$MES" -gt "$MESTOPE" ]; then
        false
        return
    fi
    
    # Se verifica que el pais y el sistema sean validos
    CUENTA=0
    while [ $CUENTA -lt $REGISTROS ]
    do
        # Si existe el par Pais-Sistema, el archivo es valido
        if [ "$PAIS" = "${PAISES[$CUENTA]}" \
            -a "$SISTEMA" = "${SISTEMAS[$CUENTA]}" ]; then
            true
            return
        fi
        (( CUENTA += 1 ))
    done
    
    false
}

if [ ! $ENTORNO_INICIALIZADO ]; then
    echo "Detectar: Entorno no inicializado"
    exit $ENOENTORNO
fi

# Solo se permite una instancia activa de este script.
contar_instancias detectar
if [ $CANTINST -gt 1 ]; then 
    imprimir "Detectar ya esta corriendo" W
    exit 0
fi

imprimir "Detectar iniciado" I

# El directorio de entrada de archivos debe existir
if [ ! -d "$DATADIR" ]; then
    imprimir "El directorio de entrada $DATADIR no existe" SE
    exit $ENODATADIR
fi

# Los directorios donde se moveran los archivos, de no existir, se crean
if [ ! -d "$DIROK" ]; then
    # Si existe un archivo con el nombre de uno de los directorios
    #+se esta ante un error severo.
    if [ -e "$DIROK" ]; then
        imprimir "El directorio de aceptados $DIROK no es un directorio" SE
        exit $ENODIR
    fi
    mkdir "$DIROK"
fi
if [ ! -d "$DIRNOK" ]; then
    if [ -e "$DIRNOK" ]; then
        imprimir "El directorio de aceptados $DIROK no es un directorio" SE
        exit $ENODIR
    fi
    mkdir "$DIRNOK"
fi

CICLOS=0

# Se lee por unica vez la tabla de paises y sistemas,
#+por lo tanto no puede cambiar durante la ejecucion
leer_paises_y_sistemas

# Bucle principal del demonio
while [ 1 ]
do
    (( CICLOS += 1 ))
    imprimir "Ciclo #$CICLOS"
    
    # Se procesan los archivos del directorio de entrada
    LISTA=$(ls -1 "$DATADIR")
    ARCHIVOS=( $LISTA ) # Array que contiene cada linea de la lista como un elemento
    # Para cada elemento del directorio se realiza el procesamiento necesario
    for ARCHIVO in ${ARCHIVOS[*]}
    do
        # No se procesan directorios
        if [ -d "$DATADIR/$ARCHIVO" ]; then continue; fi
        
        # Segun la validez del nombre, se acepta o rechaza el archivo
        if validar_nombre $ARCHIVO; then
            mover "$DATADIR/$ARCHIVO" "$DIROK" detectar
            imprimir "Recibido: $ARCHIVO"
        else
            mover "$DATADIR/$ARCHIVO" "$DIRNOK" detectar
            imprimir "Rechazado: $ARCHIVO"
        fi
    done
    
    # Variable que indica si entre este ciclo y el siguiente el
    #+demonio duerme o no. Si hay archivos en el directorio de
    #+validos, no se dormira para permitir su procesamiento inmediato.
    DORMIR=1
    # Si hay archivos de entrada validos se invoca al interprete
    LISTA=$(ls -1 "$DIROK")
    ARCHIVOS=( $LISTA )
    if [ ${#ARCHIVOS[*]} -gt 0 ]; then
        DORMIR=0
        # Solo puede correr una instancia del interprete
        contar_instancias "interprete"
        if [ $CANTINST -lt 1 ]; then
            interprete &
            intPID=$!
            wait
            COD=$?
            if [ $COD -eq 0 ]; then
                imprimir "PID de interprete: $intPID"
            else
                imprimir "Error de interprete #$COD: ${ERRDESC[$?]}"
            fi
        fi
    fi
    
    # Se sale al alcanzar la cantidad maxima de ciclos de ejecucion
    if [ "$CICLOS" -ge "$CANLOOP" ]; then
        imprimir "Cantidad maxima de ciclos alcanzada" I
        exit 0
    fi
    
    if [[ $DORMIR ]]; then sleep $TESPERA; fi
done
