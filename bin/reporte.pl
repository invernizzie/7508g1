#! /usr/bin/perl

use Switch;

# Variables global.
$usId = "yo";
$pais = "A";
$sistema = 6;
$grabarListados = 0;
$grabarModificaciones = 0;
$archivoListados = "Listados.txt";
$archivoModificaciones = "Modificaciones.txt";

# Paises y sistemas válidos.
%paisesValidos;
%sistemasValidos;

# Valida que el entorno esté inicializado y aborta la ejecución con error en 
# caso de ser así.
sub validarEntorno {
  
  if (!$ENV{ENTORNO_INICIALIZADO}) {
    print "Entorno no inicializado\n";
    exit 1;
  }
}

# Inicializa las varibles gobales %paisesValidos y %sistemasValidos a partir del
# archivo p-s.tab.
sub inicializarPaisesSistemasValidos {
  
  # TODO obtener el nombre de archivo a partir de la varible de entorno DATADIR.
  my $filename = "../conf/p-s.tab";
  open (PSTAB, $filename) || die "No se pudo abrir el archivo $filename";
  
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


# No valida nada.
sub validacionNula{

  return @_[0];
}

# TODO
sub validarPais {
  
  my $pais = @_[0];
  return exists ($paisesValidos{$pais}) ? $pais : "";
} 

# TODO
sub validarSistema{
  
  my $sistema = @_[0];
  return exists ($sistemasValidos{$sistema}) ? $sistema : "";
}

# Se permiten todos los anios mayores a 1900.
sub validarAnio{

  my $anio = int(@_[0]); 
  return $anio >= 2000 ? $anio : "";
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
    chop($respuesta);
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

  # TODO Usar glog?
  open(ARCHIVO,$fileName) || die ("No se pudo abrir $filename\n");

  my $linea;
  while ($linea = <ARCHIVO>){
   
    chomp($linea);
    # Filtros!
    my ($pasaFiltro, $nContrato) = &$funcionFiltro($linea, @filtros);
    if ($pasaFiltro){
      $filtrado{$nContrato} = $linea;
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

sub procesarModificacion{

  my ($rCons,$rPpiFiltrado) = @_;
  my $key;
  my $modificacion;

  my ($seg, $min, $hora, $dia, $mes, $anho, @zape) = localtime(time);
  my $fecha = $dia."/".$mes."/".$anho;   

  my @cons = @$rCons;
  my %ppiFiltrado = %$rPpiFiltrado;
  my (@entradaConsulta,@entradaMaestro);

  foreach my $elemento (@cons){
    
    @entradaConsulta = split("-",$elemento);
    my $nContrato = @entradaConsulta[4];
    
    @entradaMaestro = split("-",$ppiFiltrado{$nContrato});
    
    $modificacion = $modificacion.join("-", @entradaMaestro[1,2,3,8,6,10,11,12,13,14], @entradaConsulta[3],$fecha,$usId)."\n";
  }
  
  return $modificacion;
}

sub realizarConsulta{

  my @filtrosPPI = @_;
  my @filtrosContrato = @_[1..$#_];
  my $pais = $_[0];
  my $key;

  # TODO Obtener las rutas de los archivos a partir de la variable de entorno
  # DATADIR.
  my %ppiFiltrado = &filtrarArchivo("PPI.mae","filtroArchivoMaestro",@filtrosPPI);
  my %contratosFiltrado = &filtrarArchivo("CONTRAT.$pais","filtroArchivoContratos",@filtrosContrato);
  my (@consA, @consB, @consC, @consD, @consE1, @consE2, @consF1, @consF2); 

  foreach $key (keys(%contratosFiltrado)) {

    my $lineaContrato = $contratosFiltrado{$key}; 
    my $lineaMaestro = $ppiFiltrado{$key};  
    
    if ($lineaMaestro){

      my @arrayMaestro = split("-",$lineaMaestro);    
      my @arrayContrato = split("-",$lineaContrato);
  
      # Calcula el monto restante.
      my ($MT_CRD, $MT_IMPAGO, $MT_INDE, $MT_OTRSUMDC) = @arrayMaestro[10,11,13,14];
      my $montoMaestro = $MT_CRD + $MT_IMPAGO + $MT_INDE - $MT_OTRSUMDC;
      my $estadoMaestro = @arrayMaestro[6];
    
      my ($estadoContrato, $montoContrato) = @arrayContrato[5,11];
      
      $lineaConsulta = join("-", $estadoContrato, $estadoMaestro, 
                            $montoContrato, $montoMaestro, $key);
      $igualMonto = ($montoMaestro == $montoContrato);
  
      if (($estadoMaestro eq "SANO") && ($estadoContrato eq "SANO")){
        $igualMonto ? push(@consA,$lineaConsulta) : push(@consC,$lineaConsulta);
      }
      elsif (($estadoMaestro eq "DUDOSO") && ($estadoContrato eq "DUDOSO")){
	      $igualMonto ? push(@consB,$lineaConsulta) : push(@consD,$lineaConsulta);
      }
      elsif (($estadoMaestro eq "SANO") && ($estadoContrato eq "DUDOSO")){
	      $igualMonto ? push(@consE2,$lineaConsulta) : push(@consF2,$lineaConsulta);
      }
      elsif (($estadoMaestro eq "DUDOSO") && ($estadoContrato eq "SANO")){
	      $igualMonto ? push(@consE1,$lineaConsulta) : push(@consF1,$lineaConsulta);	
      }

   }
   else{
	# TODO llamas al glog. ("No existe el numero de contrato en el archivo maestro" SE)
   }
  }

  # Listados.
  print "LISTADO\n";
  my $consultaA = "Contratos comunes sanos con identico Monto Restante: \n".&procesarConsulta(@filtrosPPI,@consA)."\n";
  print "$consultaA\n";

  my $consultaB = "Contratos comunes dudosos con identico Monto Restante: \n".&procesarConsulta(@filtrosPPI,@consB)."\n";
  print "$consultaB\n";
  
  my $consultaC = "Contratos comunes sanos con diferente Monto Restante: \n".&procesarConsulta(@filtrosPPI,@consC)."\n";
  print "$consultaC\n";

  my $consultaD = "Contratos comunes dudosos con diferente Monto Restante: \n".&procesarConsulta(@filtrosPPI,@consD)."\n";
  print "$consultaD\n";

  my $consultaE = "Contratos comunes con diferente estado con identico Monto Restante: \n".
		  &procesarConsulta(@filtrosPPI,@consE1)."\n".&procesarConsulta(@filtrosPPI,@consE2)."\n";
  print "$consultaE\n";
  
  my $consultaF = "Contratos comunes con diferente estado con diferente Monto Restante: \n".
		  &procesarConsulta(@filtrosPPI,@consF1)."\n".&procesarConsulta(@filtrosPPI,@consF2)."\n";
  print "$consultaF\n";
  
  if ($grabarListados){ 
    open(LISTADOS,">$archivoListados");
    print LISTADOS $consultaA;
    print LISTADOS $consultaB;
    print LISTADOS $consultaC;
    print LISTADOS $consultaD;
    print LISTADOS $consultaE;
    print LISTADOS $consultaF;
    close(LISTADOS);
  };
 
  # Modificaciones.
  print "MODIFICACIONES\n";
  my $modicaciones = &procesarModificacion(\@consC,\%ppiFiltrado).
                     &procesarModificacion(\@consE2,\%ppiFiltrado).
                     &procesarModificacion(\@consF2,\%ppiFiltrado);
  print "$modicaciones\n";

  if ($grabarModificaciones){
    open(MODIFICACIONES,">$archivoModificaciones");
    print MODIFICACIONES $modicaciones;
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
#&validarEntorno();
&inicializarPaisesSistemasValidos();
&menu();

