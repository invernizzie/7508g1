#! /usr/bin/perl

use Switch;

# Variables global.
$usId = $ENV{"USER"};
$pais = "A";
$sistema = 6;
$grabarListados = 0;
$grabarModificaciones = 0;
$LISTDIR = $ENV{"DATADIR"}."/list/";
$archivoListadosTotales = $LISTDIR."ListadosTotales.txt";

# Paises y sistemas válidos.
%paisesValidos;
%sistemasValidos;

# Valida que el entorno esté inicializado y aborta la ejecución con error en 
# caso de ser así.
sub validarEntorno {
  
  if (!$ENV{"ENTORNO_INICIALIZADO"}) {
    print "Entorno no inicializado\n";
    exit 1;
  }
}

sub glog {
  my ($mensaje, $tipo) = @_;
  #print "Reporte: $mensaje\n";
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
  
  my $psTabDir = $ENV{"GRUPO"}."/conf/p-s.tab";
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

  return @_[0];
}

sub validarPais {

  my $pais = @_[0];
  return exists ($paisesValidos{$pais}) ? $pais : "";
} 

sub validarSistema{
  
  my $sistema = @_[0];
  return exists ($sistemasValidos{$sistema}) ? $sistema : "";
}

# Se permiten todos los anios mayores a 1900.
sub validarAnio{

  my $anio = int(@_[0]); 
  #return $anio >= 2000 ? $anio : "";
  
  return 2000 <= $anio && $anio <= &obtenerAnioActual() ? $anio : "";
}

# Valida que un mes dado esté entre 1 y 12 y lo retorna.
sub validarMes{
  
  my $mes = int(@_[0]); 
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
  my $opcion;
  my $respuesta;
  
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

  my $pais = &cargaParametro("pais","validarPais", "mostrarPaisesValidos");
  my $sistema = &cargaParametroOpcional("sistema","validarSistema", 
                                        "mostrarSistemasValidos");
  my $anio;
  my $mes;

  if ($anio = &cargaParametroOpcional("anio", "validarAnio")){
    $mes = &cargaParametroOpcional("mes", "validarMes");
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
  my ($consulta,$cantidadContratos,$montoMaestro,$montoContrato);
  
  $cantidadContratos = $#entradas + 1;

  foreach my $elemento (@entradas) {
    
    @entrada = split("-",$elemento);
    $montoMaestro += @entrada[3];
    $montoContrato += @entrada[2];
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
  my $consultaSinFormato=$_[0];
 # print "consulta sin formato :" .  $consultaSinFormato;
  chomp($consultaSinFormato);
  my @entrada= split("-",$consultaSinFormato);
  my $linea;
    
  foreach my $campo (@entrada){
    $linea = $linea . sprintf("%9s %s", $campo,"|");
  }
  $linea = $linea . "\n";
  return $linea;
}

sub crearModificacionFormateada(){
 
 my $rArrayModificacion = @_[0];
 
 foreach $modificacionSinFormato (@$rArrayModificacion){
 
  chomp($modificacionSinFormato);
  my @entrada= split("-",$modificacionSinFormato);
  $modificacionFormateada= $modificacionFormateada . sprintf '%12s %s', $pais,"|";
  $modificacionFormateada= $modificacionFormateada . sprintf '%12s %s', $entrada[0],"|";
  $modificacionFormateada= $modificacionFormateada . sprintf '%12s %s', $entrada[1],"|";
  $modificacionFormateada= $modificacionFormateada . sprintf '%12s %s', $entrada[2],"|";
  $modificacionFormateada= $modificacionFormateada . sprintf '%12s %s', $entrada[3],"|";
  $modificacionFormateada= $modificacionFormateada . sprintf '%12s %s', $entrada[5],"|";
  $modificacionFormateada= $modificacionFormateada . sprintf '%12s %s', $entrada[11],"|"; 
  $modificacionFormateada= $modificacionFormateada . "\n";  
 }
 
 return $modificacionFormateada;   
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
  #$linea = sprintf '%42s %s',"Parametros","|";
  my $linea = sprintf '%9s %s',"Pais","|";  
  $linea = $linea . sprintf '%9s %s',"Sistema","|";
  $linea = $linea . sprintf '%9s %s',"Anio","|";
  $linea = $linea . sprintf  '%9s %s',"Mes","|";
  $linea = $linea . sprintf '%9s %s',"Cant Con","|";
  $linea = $linea . sprintf '%9s %s',"Est Cont","|";
  $linea = $linea . sprintf  '%9s %s',"Est Mae","|";
  $linea = $linea . sprintf  '%9s %s',"Monto Con","|";
  $linea = $linea . sprintf  '%9s %s',"Monto Mae","|";
  $linea = $linea . sprintf  "\n";
  return $linea;
}

sub crearEncabezadoModificaciones{
  #$linea = sprintf '%42s %s',"Parametros","|";
  my $linea = sprintf '%12s %s',"Pais","|";  
  $linea = $linea . sprintf '%12s %s',"Sistema","|";
  $linea = $linea . sprintf '%12s %s',"Anio","|";
  $linea = $linea . sprintf  '%12s %s',"Mes","|";
  $linea = $linea . sprintf '%12s %s',"Num Cont","|";
  $linea = $linea . sprintf '%12s %s',"Estado","|";
  $linea = $linea . sprintf  '%12s %s',"Monto","|";
  $linea = $linea . sprintf  "\n";
  return $linea;
}

sub procesarModificacion{

  my ($rCons,$rPpiFiltrado,$rArrayModificaciones) = @_;
  my $modificacion;

  my ($seg, $min, $hora, $dia, $mes, $anho, @zape) = localtime(time);
  # Los anios comienzan en 1900. Los meses van de 0 a 11.
  my $fecha = $dia."/".($mes+1)."/".($anho+1900);   

  my @cons = @$rCons;
  my %ppiFiltrado = %$rPpiFiltrado;
  my (@entradaConsulta,@entradaMaestro);

  foreach my $elemento (@cons){
    
    @entradaConsulta = split("-",$elemento);
    my $nContrato = @entradaConsulta[4];
    
    @entradaMaestro = split("-",$ppiFiltrado{$nContrato});
  
    my $consultaActual = join("-", @entradaMaestro[1,2,3],$nContrato,
                               @entradaMaestro[8,6,10..14], 
                               @entradaConsulta[3],$fecha,$usId)."\n";
    push(@$rArrayModificaciones,$consultaActual);
    $modificacion = $modificacion.$consultaActual;
  }
  
  return $modificacion;
}

sub realizarConsulta{

  my @filtrosPPI = @_;
  my @filtrosContrato = @_[1..$#_];
  my $pais = $_[0];

  my $ppiDir       = $ENV{"DATADIR"}."/mae/PPI.mae";
  my $contratosDir = $ENV{"DATADIR"}."/new/CONTRAT.$pais";
  
  my %ppiFiltrado = 
    &filtrarArchivo($ppiDir,       "filtroArchivoMaestro",   @filtrosPPI);
  my %contratosFiltrado = 
    &filtrarArchivo($contratosDir, "filtroArchivoContratos", @filtrosContrato);
  
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
      my $estadoMaestro = @arrayMaestro[6];
    
      my ($estadoContrato, $montoContrato) = @arrayContrato[5,11];
      
      $lineaConsulta = join("-", $estadoContrato, $estadoMaestro, 
                            $montoContrato, $montoMaestro, $nContrato);
      $igualMonto = ($montoMaestro == $montoContrato);
  
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
      &glogAndExit ("No existe el numero de contrato $nContrato en el archivo maestro",
             "E");
    }
  }

  # Listados.
  print "\nLISTADO\n";
  my @consultasFormateadas;
  my $consulta;
  my $consultaAux;
  my $encabezadoConsulta=&crearEncabezadoConsulta();
  
  $consultaSinFormato = &procesarConsulta(@filtrosPPI,@consA)."\n";
  $descConsulta = "Contratos comunes sanos con identico Monto Restante: \n";
  $consulta = &crearConsultaFormateada($consultaSinFormato);
  push(@consultasFormateadas,$descConsulta.$encabezadoConsulta.$consulta);
 
  $consultaSinFormato= &procesarConsulta(@filtrosPPI,@consB)."\n";
  $descConsulta = "Contratos comunes dudosos con identico Monto Restante: \n";
  $consulta = &crearConsultaFormateada($consultaSinFormato);
  push(@consultasFormateadas,$descConsulta.$encabezadoConsulta.$consulta);
 
  $descConsulta = "Contratos comunes sanos con diferente Monto Restante: \n";
  $consultaSinFormato=&procesarConsulta(@filtrosPPI,@consC)."\n";
  $consulta = &crearConsultaFormateada($consultaSinFormato);
  push(@consultasFormateadas,$descConsulta.$encabezadoConsulta.$consulta);
  
  $descConsulta = "Contratos comunes dudosos con diferente Monto Restante: \n";
  $consultaSinFormato=&procesarConsulta(@filtrosPPI,@consD)."\n";
  $consulta = &crearConsultaFormateada($consultaSinFormato);
  push(@consultasFormateadas,$descConsulta.$encabezadoConsulta.$consulta);
 
  $descConsulta = "Contratos comunes con diferente estado con identico Monto Restante: \n";
	$consultaSinFormato= &procesarConsulta(@filtrosPPI,@consE1)."\n";
  $consulta = &crearConsultaFormateada($consultaSinFormato);   
	$consultaSinFormato= &procesarConsulta(@filtrosPPI,@consE2)."\n";
  $consultaAux = &crearConsultaFormateada($consultaSinFormato);
  push(@consultasFormateadas,$descConsulta.$encabezadoConsulta.$consulta.$consultaAux);

  $descConsulta = "Contratos comunes con diferente estado con diferente Monto Restante: \n";
	$consultaSinFormato=&procesarConsulta(@filtrosPPI,@consF1)."\n";
  $consulta = &crearConsultaFormateada($consultaSinFormato);
	$consultaSinFormato=&procesarConsulta(@filtrosPPI,@consF2)."\n";
  $consultaAux = &crearConsultaFormateada($consultaSinFormato);
  push(@consultasFormateadas,$descConsulta.$encabezadoConsulta.$consulta.$consultaAux);

  if ($grabarListados){ 
    open(LISTADOS,">>$archivoListadosTotales");
    foreach my $string (@consultasFormateadas){
      print LISTADOS &convNotacionComa($string);
    }
    close(LISTADOS); 
    
    my $indice = 0;
    foreach my $idList ("A","B","C","D","E","F"){
      open(arch  , ">>".$LISTDIR."list".$idList.".".$usId);
      print arch $consultasFormateadas[$indice];
      close(arch);
      $indice++;
    }
  }

  foreach my $string (@consultasFormateadas){
    print &convNotacionComa($string);
   }
   
  # Modificaciones.
  print "\nMODIFICACIONES\n";
  @arrayModificaciones;
  my $modicaciones = &procesarModificacion(\@consC,\%ppiFiltrado,\@arrayModificaciones).
                     &procesarModificacion(\@consE2,\%ppiFiltrado,\@arrayModificaciones).
                     &procesarModificacion(\@consF2,\%ppiFiltrado,\@arrayModificaciones);
  
  my $modificacionesFormateadas = &crearModificacionFormateada(\@arrayModificaciones);

  print &crearEncabezadoModificaciones;
  print $modificacionesFormateadas;
  
  if ($grabarModificaciones){
    $archivoModificaciones = $ENV{"DATADIR"}."new/MODIF.$pais";
    open(MODIFICACIONES,">>$archivoModificaciones");
    print MODIFICACIONES convNotacionComa($modicaciones);
    close(MODIFICACIONES);
  }
  
  print "Presione Enter para continuar";
  my $enter = <STDIN>;
}

sub menu{

  my $salir = 0;

  while (!$salir){

    system("clear");
    print "Paramatros actuales de consulta, \Pais: $pais - ".
          "Sistema: $sistema - Anio: $anio - Mes: $mes\n";
    print "1- Cargar parametros de consulta.\n";
    print "2- ".($grabarListados ? "Desactivar" : "Activar").
          " grabacion de listados de consultas.\n";
    print "3- ".($grabarModificaciones ? "Desactivar" : "Activar").
          " grabacion de modificaciones de contratos.\n";
    print "4- Realizar consulta.\n";
    print "5- Salir.\n";
    print "Opcion: ";
    $opcion = <STDIN>;
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
