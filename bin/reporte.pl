#! /usr/bin/perl

# Para usar switch.
use Switch;

# Para que el compilador sea mas estricto.
use strict;
use warnings;

# Variables global.

my $pais = "A";
my $sistema = 6;
my $anio = "";
my $mes = "";
my $grabarListados = 0;
my $grabarModificaciones = 0;

# Paises y sistemas válidos.
my %paisesValidos;
my %sistemasValidos;

# Constantes.
my $USER_ID = $ENV{"USER"};
my $DATADIR = $ENV{"DATADIR"};
my $LISTDIR = "$DATADIR/list";
my $GRUPO = $ENV{"GRUPO"};


# Valida que el entorno esté inicializado y aborta la ejecución con error en 
# caso de ser así.
sub validarEntorno {
  
  if (!$ENV{"ENTORNO_INICIALIZADO"}) {
    print "Entorno no inicializado\n";
    exit 1;
  }
  
  foreach my $var ("DATADIR", "GRUPO") {
    if (!$ENV{$var}) {
      &glogAndExit("No exite la variable de entorno $var", "SE", 1);
    }
  }
  
  if (-e $LISTDIR && ! -d $LISTDIR) {
    &glogAndExit("$LISTDIR no es un directorio", "SE", 1);
  }
}

sub glog {
  my ($mensaje, $tipo) = @_;
  print "Reporte: $mensaje\n";
  `glog reporte "$tipo" "$mensaje"`
}

sub glogAndExit {
  my ($mensaje, $tipo, $exitCode) = @_;
  glog ($mensaje, $tipo);
  exit $exitCode;
}

# Inicializa las varibles gobales %paisesValidos y %sistemasValidos a partir del
# archivo p-s.tab.
sub inicializarPaisesSistemasValidos {
  
  my $psTabDir = "$GRUPO/conf/p-s.tab";
  open (PSTAB, $psTabDir) || 
    glogAndExit ("No se pudo abrir el archivo $psTabDir", "SE", 1);
  
  my (%paises, %sistemas);
  while (my $linea = <PSTAB>) {
    chomp ($linea);
    my @psReg = split("-", $linea);
    $paises  {$psReg[0]} = $psReg[1];
    $sistemas{$psReg[2]} = $psReg[3];
  }
  
  close (PSTAB);
  
  %paisesValidos = %paises;
  %sistemasValidos = %sistemas;
}

sub mostrarPaisesValidos {
  print "    Paises Validos \n";
  foreach my $idPais (keys(%paisesValidos)) {
    print "      $idPais: ".$paisesValidos{$idPais}."\n";
  }
}

sub mostrarSistemasValidos {
  print "    Sistemas Validos:\n";
  foreach my $idSist (keys(%sistemasValidos)) {
    print "      $idSist: ".$sistemasValidos{$idSist}."\n";
  }
}

sub obtenerAnioActual {
  my @fecha = localtime(time);
  return $fecha[5] + 1900;
}

# No valida nada.
sub validacionNula{

  return $_[0];
}

sub validarPais {

  my $pais = $_[0];
  return exists ($paisesValidos{$pais}) ? $pais : "";
} 

sub validarSistema{
  
  my $sistema = $_[0];
  return exists ($sistemasValidos{$sistema}) ? $sistema : "";
}

# Se permiten todos los anios mayores a 1900.
sub validarAnio{

  my $anio = int($_[0]); 
  #return $anio >= 2000 ? $anio : "";
  
  return 2000 <= $anio && $anio <= &obtenerAnioActual() ? $anio : "";
}

# Valida que un mes dado esté entre 1 y 12 y lo retorna.
sub validarMes{
  
  my $mes = int($_[0]); 
  return $mes >= 1 && $mes <= 12 ? $mes : "";
}

# Solicita al usuario que cargue un parámetro con un dado nombre y una dada 
# función de validación.
sub cargaParametro{

  my ($parametro, $validacion, $mostrarValidos) = @_;
  my ($respuesta, $respuestaValidada);

  while (!$respuestaValidada){
    
    print "    Ingrese el $parametro: ";
    $respuesta = <STDIN>;
    chomp($respuesta);
    $respuestaValidada = &$validacion($respuesta);
    if (!$respuestaValidada) {
	    print "    El $parametro \"$respuesta\" es invalido =(\n";
	    if ($mostrarValidos) {
	      &$mostrarValidos();
	    }
    }
  }
  return $respuesta;
}


# Permite la carga de parametros opcionales como el sistema, anio y mes.
sub cargaParametroOpcional{
  
  my ($parametro, $validacion, $mostrarValidos) = @_;
  my $opcion = "";
  my $respuesta = "";
  
  while($opcion ne "s" && $opcion ne "n"){
    
    print "    Desea ingresar el $parametro? s/n ";
    $opcion = <STDIN>;
    chop($opcion);
  }

  if ($opcion eq "n"){
    return $respuesta;
  }

  return &cargaParametro($parametro,$validacion, $mostrarValidos);
}


# Cargar parametros de consulta (Pais, Sistema, Anio y Mes)
sub cargarParametrosDeConsulta{

  my $pais = &cargaParametro("pais",\&validarPais, \&mostrarPaisesValidos);
  my $sistema = &cargaParametroOpcional("sistema",\&validarSistema, 
                                        \&mostrarSistemasValidos);
  my $anio = "";
  my $mes = "";

  if ($anio = &cargaParametroOpcional("anio", \&validarAnio)){
    $mes = &cargaParametroOpcional("mes", \&validarMes);
  }
  
  return $pais, $sistema, $anio, $mes;
}

sub filtroArchivoMaestro{

  #print "filtro maestro @_\n";
  my ($linea, $filtroPais, $filtroSistema, $filtroAnio, $filtroMes) = @_;
  my @registro = split("-",$linea);
  my ($pais, $sistema, $anio, $mes) = @registro[0..3];
    
  # Filtros!
  my $filtroOk = (!$filtroPais    || $pais    eq $filtroPais)    &&
                 (!$filtroSistema || $sistema == $filtroSistema) &&
                 (!$filtroAnio    || $anio    == $filtroAnio)    &&
                 (!$filtroMes     || $mes     == $filtroMes);

  my $nContrato = $registro[7];
  return $filtroOk, $nContrato;
}

sub filtroArchivoContratos{

  #print "filtro contrato @_\n";
  my ($linea, $filtroSistema, $filtroAnio, $filtroMes) = @_;
  my @registro = split("-",$linea);
  my ($sistema, $anio, $mes) = @registro[0..2];
   
  # Filtros!
  my $filtroOk = (!$filtroSistema || $sistema == $filtroSistema) &&
                 (!$filtroAnio    || $anio    == $filtroAnio)    &&
                 (!$filtroMes     || $mes     == $filtroMes);
  
  my $nContrato = $registro[3];
  return $filtroOk, $nContrato;
}

# Filtra el archivo maestro a partir de los parámetros de consulta (pais, 
# sistema, año y mes) y retorna un hash con los contratos filtrados, de la 
# forma: clave = número de contrato, valor = <estado>-<monto>
sub filtrarArchivo {

  my ($fileName, $funcionFiltro) = @_[0,1];
  my (@filtros) = @_[2..$#_];

  # Hash con registros filtrados del archivo correspondiente.
  my %filtrado;

  open(ARCHIVO, $fileName) || 
    glogAndExit ("No se pudo abrir $fileName", "SE", 1);

  my $linea;
  while ($linea = <ARCHIVO>){
   
    chomp($linea);
    # Filtros!
    my ($pasaFiltro, $nContrato) = &$funcionFiltro($linea, @filtros);
    if ($pasaFiltro){
      $filtrado{$nContrato} = &convNotacionPunto($linea);
    }
  }
  
  close(ARCHIVO);
  
  return %filtrado;   
}

sub procesarConsulta{

  my @filtros = @_[0..3];
  my @entradas = @_[4..$#_];
  my @entrada;  
  my ($montoMaestro,$montoContrato);
  
  my $cantidadContratos = $#entradas + 1;

  foreach my $elemento (@entradas) {
    
    @entrada = split("-",$elemento);
    $montoMaestro += $entrada[3];
    $montoContrato += $entrada[2];
  }

  if ($cantidadContratos > 0) {
    return join("-",@filtros,$cantidadContratos,@entrada[0,1],$montoContrato,
                $montoMaestro);
 }
 else {
    return "";
 }
 
}


sub crearConsultaFormateada{
 # print "entro a imprimir consulta\n";
 # print "consulta sin formato :" .  $consultaSinFormato;
  my $consultaSinFormato = $_[0];
  my @entrada= split("-",$consultaSinFormato);
  my $linea;
    
  foreach my $campo (@entrada){
    $linea = $linea.sprintf("%9s |", $campo);
  }
  $linea = "$linea\n";
  $linea = &convNotacionComa($linea);
  return $linea;
}

sub crearModificacionFormateada(){
 
  my @modificaciones = @_;

  my $modificacionFormateada = "";
  foreach my $modificacionSinFormato (@modificaciones){

    chomp($modificacionSinFormato);
    my @entrada= split("-",$modificacionSinFormato);
    
    # TODO Es medio cualquiera acceder a la variable global $pais así...
    # muy asqueroso.
    foreach my $campo ($pais, @entrada[0..3,5,11]) {
      $modificacionFormateada = 
        $modificacionFormateada.sprintf('%12s |', $campo);
    }
    $modificacionFormateada= $modificacionFormateada."\n";  
  }

  return &convNotacionComa($modificacionFormateada);   
}

sub convNotacionPunto{
  my $nroOriginal= $_[0];
  my @partes=split(",",$nroOriginal);
  my $numero =join(".",@partes);
  return $numero;
}

sub convNotacionComa{
  my $nroOriginal= $_[0];
  my @partes=split(/\./,$nroOriginal);
  my $numero=join(",",@partes);
  return "$numero";
}

sub crearEncabezadoConsulta{
  
  my $linea = "";
  my @campos = ("Pais", "Sistema", "Anio", "Mes", "Cant Con", "Est Cont",
                "Est Mae", "Monto Con", "Monto Mae");
  foreach my $campo (@campos) {
    $linea = $linea.sprintf('%9s |', $campo);
  }
  $linea = "$linea\n";
  return $linea;
}

sub crearEncabezadoModificaciones{

  my $linea = "";
  my @campos = ("Pais", "Sistema", "Anio", "Mes", "Num Cont", "Estado", 
                "Monto");
  foreach my $campo (@campos) {
    $linea = $linea.sprintf('%12s |', $campo);
  }
  $linea = "$linea\n";
  return $linea;
}

sub procesarModificacion{

  my ($rCons,$rPpiFiltrado) = @_;
  my @modificaciones;

  my ($seg, $min, $hora, $dia, $mes, $anho, @zape) = localtime(time);
  # Los anios comienzan en 1900. Los meses van de 0 a 11.
  my $fecha = $dia."/".($mes+1)."/".($anho+1900);   

  my @cons = @$rCons;
  my %ppiFiltrado = %$rPpiFiltrado;

  foreach my $elemento (@cons){
    
    my @entradaConsulta = split("-",$elemento);
    my $nContrato = $entradaConsulta[4];
    
    my @entradaMaestro = split("-",$ppiFiltrado{$nContrato});
  
    my $consultaActual = join("-", @entradaMaestro[1,2,3],$nContrato,
                               @entradaMaestro[8,6,10..14], 
                               $entradaConsulta[3],$fecha,$USER_ID)."\n";
    push(@modificaciones,$consultaActual);
  }
  
  return @modificaciones;
}

sub realizarConsulta{

  my @filtrosPPI = @_;
  my @filtrosContrato = @_[1..$#_];
  my $pais = $_[0];

  my $ppiDir       = "$DATADIR/mae/PPI.mae";
  my $contratosDir = "$DATADIR/new/CONTRAT.$pais";
  
  my %ppiFiltrado = 
    &filtrarArchivo($ppiDir,       \&filtroArchivoMaestro,   @filtrosPPI);
  my %contratosFiltrado = 
    &filtrarArchivo($contratosDir, \&filtroArchivoContratos, @filtrosContrato);
  
  my (@consA, @consB, @consC, @consD, @consE1, @consE2, @consF1, @consF2); 

  foreach my $nContrato (keys(%contratosFiltrado)) {
    
    if (exists $ppiFiltrado{$nContrato}){
    
      my $lineaContrato = $contratosFiltrado{$nContrato}; 
      my $lineaMaestro = $ppiFiltrado{$nContrato};  

      my @arrayMaestro = split("-",$lineaMaestro);    
      my @arrayContrato = split("-",$lineaContrato);
  
      # Calcula el monto restante.
      my ($MT_CRD, $MT_IMPAGO, $MT_INDE, $MT_OTRSUMDC) = 
          @arrayMaestro[10,11,13,14];
  
      my $montoMaestro = $MT_CRD + $MT_IMPAGO + $MT_INDE - $MT_OTRSUMDC;
      my $estadoMaestro = $arrayMaestro[6];
    
      my ($estadoContrato, $montoContrato) = @arrayContrato[5,11];
      
      my $lineaConsulta = join("-", $estadoContrato, $estadoMaestro, 
                            $montoContrato, $montoMaestro, $nContrato);
      my $igualMonto = ($montoMaestro == $montoContrato);
  
      my $estados = "$estadoMaestro $estadoContrato";
      switch ($estados) {
        case "SANO SANO"     { $igualMonto ? push(@consA,$lineaConsulta) 
                                           : push(@consC,$lineaConsulta); }
        case "DUDOSO DUDOSO" { $igualMonto ? push(@consB,$lineaConsulta) 
                                           : push(@consD,$lineaConsulta); }
        case "SANO DUDOSO"   { $igualMonto ? push(@consE2,$lineaConsulta) 
                                           : push(@consF2,$lineaConsulta); }
        case "DUDOSO SANO"   { $igualMonto ? push(@consE1,$lineaConsulta) 
                                           : push(@consF1,$lineaConsulta); }
	      else { &glog("Estado inválido: $estados", "E"); }
      }
    }
    else{
      &glogAndExit ("No existe el numero de contrato $nContrato en el archivo".
                    " maestro", "E");
    }
  }

  # Listados.
  print "\nLISTADO\n";
  my @consultasFormateadas;
  my $encabezadoConsulta=&crearEncabezadoConsulta();
  
  # Procesa y crea una conuslta formateada usando my @filtrosPPI.
  # NOTA: definida como subrutina anónima para que no tenga visibilidad global.
  my $procesarYCrearConsFormateada = sub{
    return &crearConsultaFormateada(&procesarConsulta(@filtrosPPI, @_));
  };
  
  # Agrega una consulta formateada a my @consultasFormateadas.
  my $agregarConsultaFormateada = sub {
    my ($desc, @refsConsultas) = @_;
    my $consulta = "Contratos comunes $desc:\n$encabezadoConsulta";
    foreach my $rConsulta (@refsConsultas) {
      $consulta = $consulta.&$procesarYCrearConsFormateada(@$rConsulta);
    }
    push(@consultasFormateadas,$consulta);
  };
  
  &$agregarConsultaFormateada(
    "sanos con identico Monto Restante",    \@consA);
  &$agregarConsultaFormateada(
    "dudosos con identico Monto Restante",  \@consB);
  &$agregarConsultaFormateada(
    "sanos con diferente Monto Restante",   \@consC);
  &$agregarConsultaFormateada(
    "dudosos con diferente Monto Restante", \@consD);
  &$agregarConsultaFormateada(
    "con diferente estado con identico Monto Restante",  \@consE1, \@consE2);
  &$agregarConsultaFormateada(
    "con diferente estado con diferente Monto Restante", \@consF1, \@consF2);

  print @consultasFormateadas;

  if ($grabarListados){ 
    
    if (! -e $LISTDIR) {
      mkdir $LISTDIR || 
        glogAndExit ("No se pudo crear el directorio $LISTDIR", "SE", 1);
    }
  
    my $archivoListadosTotales = "$LISTDIR/ListadosTotales.txt";
    open(LISTADOS_TOT,">>$archivoListadosTotales") || 
      glogAndExit ("No se pudo abrir $archivoListadosTotales", "SE", 1);
    
    print LISTADOS_TOT @consultasFormateadas;
    close(LISTADOS_TOT); 
    
    my $indice = 0;
    foreach my $idList ("A","B","C","D","E","F"){
      my $archLista = "$LISTDIR/list$idList.$USER_ID";
      open(LISTADO  , ">>$archLista") ||
        glogAndExit("No se pudo abrir $archLista", "SE", 1);
      
      print LISTADO $consultasFormateadas[$indice];
      close(LISTADO);
      $indice++;
    }
  }

  
   
  # Modificaciones.
  print "\nMODIFICACIONES\n";
  my @modificaciones = (
    &procesarModificacion(\@consC,  \%ppiFiltrado),
    &procesarModificacion(\@consE2, \%ppiFiltrado),
    &procesarModificacion(\@consF2, \%ppiFiltrado),
    );
  
  my $modificacionesFormateadas = &crearModificacionFormateada(@modificaciones);
  
  print &crearEncabezadoModificaciones;
  print $modificacionesFormateadas;
  
  if ($grabarModificaciones){
      
    my $archivoModificaciones = "$DATADIR/new/MODIF.$pais";
    open(MODIFICACIONES,">$archivoModificaciones") || 
      glogAndExit ("No se pudo abrir $archivoModificaciones", "SE", 1);
    
    print MODIFICACIONES convNotacionComa(join("",@modificaciones));
    close(MODIFICACIONES);
  }
  
  print "Presione Enter para continuar";
  my $enter = <STDIN>;
}

sub menu{

  my $salir = 0;

  while (!$salir){

    system("clear");
    print "Paramatros actuales de consulta, Pais: $pais - ".
          "Sistema: $sistema - Anio: $anio - Mes: $mes\n";
    print "1- Cargar parametros de consulta.\n";
    print "2- ".($grabarListados ? "Desactivar" : "Activar").
          " grabacion de listados de consultas.\n";
    print "3- ".($grabarModificaciones ? "Desactivar" : "Activar").
          " grabacion de modificaciones de contratos.\n";
    print "4- Realizar consulta.\n";
    print "5- Salir.\n";
    print "Opcion: ";
    my $opcion = <STDIN>;
    chomp($opcion);
    
    switch ($opcion) {
	
      case 1 { ($pais,$sistema,$anio,$mes) = &cargarParametrosDeConsulta(); }
      case 2 { $grabarListados = !$grabarListados }
      case 3 { $grabarModificaciones = !$grabarModificaciones }
      case 4 { &realizarConsulta($pais,$sistema,$anio,$mes) }
      case 5 { $salir=1 }
    }
  }
  if (rand() < 0.001) { print "Sos el elegido!\n"; }
}

# Bloque principal.
&validarEntorno();
&inicializarPaisesSistemasValidos();
&menu();
