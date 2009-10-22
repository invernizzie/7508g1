#! /usr/bin/perl

use Switch;

# Valida que el entorno esté inicializado y aborta la ejecución con error en 
# caso de ser así.
sub validarEntorno {
  
  if (!$ENV{ENTORNO_INICIALIZADO}) {
    print "Entorno no inicializado\n";
    exit 1;
  }
}


# No valida nada.
sub validacionNula{

  return @_[0];
}

# TODO
sub validarPais {
  
  my $pais = @_[0];
  return $pais;
}

# TODO
sub validarSistema{
  
  my $sistema = @_[0];
  return $sistema;
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

  my ($parametro, $validacion) = @_;
  my $respuesta;

  while (!$respuesta){
    
    print "    Ingrese el $parametro: ";
    $respuesta = <STDIN>;
    chop($respuesta);
    $respuesta = &$validacion($respuesta);
    if (!$respuesta) {
	    print "    El $parametro es invalido =(\n";
    }
  }
  return $respuesta;
}


# Permite la carga de parametros opcionales como el sistema, anio y mes.
sub cargaParametroOpcional{
  
  my ($parametro, $validacion) = @_;
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

  return &cargaParametro($parametro,$validacion);
}


# Cargar parametros de consulta (Pais, Sistema, Anio y Mes)
sub cargarParametrosDeConsulta{

  my $pais = &cargaParametro("pais","validarPais");
  my $sistema = &cargaParametroOpcional("sistema","validarSistema");
  my $anio;
  my $mes;

  if ($anio = &cargaParametroOpcional("anio", "validarAnio")){
    $mes = &cargaParametroOpcional("mes", "validarMes");
  }
  
  return $pais, $sistema, $anio, $mes;
}


# Filtra el archivo maestro a partir de los parámetros de consulta (pais, 
# sistema, año y mes) y retorna un hash con los contratos filtrados, de la 
# forma: clave = número de contrato, valor = <estado>-<monto>
sub filtrarArchivoMaestro{

  my ($filtroPais, $filtroSistema, $filtroAnio, $filtroMes) = @_;

  # Nombre del archivo maestro. TODO que sea $ENV{"GRUPO"}."/loquesea/PPI.mae"
  my $fileName = "PPI.mae";

  # Hash con registros filtrados del archivo maestro PPI.
  my %ppiFiltrado;

  # TODO Usar glog?
  open(PPI,$fileName) || die ("No se pudo abrir $filename\n");

  my $linea;
  while ($linea = <PPI>){
   
    chomp($linea);
    my @registro = split("-",$linea);
    my ($pais, $sistema, $anio, $mes) = @registro[0..3];
    
    # Filtros!
    if ( (!$filtroPais    || $pais    eq $filtroPais)    &&
         (!$filtroSistema || $sistema eq $filtroSistema) &&
         (!$filtroAnio    || $anio    eq $filtroAnio)    &&
         (!$filtroMes     || $mes     eq $filtroMes)        ) {

      # El registro pasa todos los filtros!
      my ($estado, $nContrato) = @registro[6,7];

      # Calcula el monto restante.
      my ($MT_CRD, $MT_IMPAGO, $MT_INDE, $MT_OTRSUMDC) = @registro[10,11,13,14];
      my $monto = $MT_CRD + $MT_IMPAGO + $MT_INDE - $MT_OTRSUMDC;

      $ppiFiltrado{$nContrato} = $estado."-".$monto;
      #print "exito ".$ppiFiltrado{$nContrato}."\n";
    }
  }

  close(PPI);

  return %ppiFiltrado;   
}


sub filtrarArchivoContratos{

  my ($pais, $filtroSistema, $filtroAnio, $filtroMes) = @_;

  # TODO Lo mismo que con el maestro.
  my $fileName = "CONTRACT.$pais";

  # Hash con registros filtrados del archivo de contratos.
  my %contratos;

  # TODO Usar glog?
  open(CONTRATOS,$fileName) || die ("No se pudo abrir $filename\n");


  my $linea;
  while ($linea = <CONTRATOS>){
   
    chomp($linea);
    my @registro = split("-",$linea);
    my ($sistema, $anio, $mes) = @registro[0..2];
    
    # Filtros!
    if ( (!$filtroSistema || $sistema eq $filtroSistema) &&
         (!$filtroAnio    || $anio    eq $filtroAnio)    &&
         (!$filtroMes     || $mes     eq $filtroMes)        ) {

      # El registro pasa todos los filtros!
      my ($estado, $nContrato, $monto) = @registro[6, 7, 11];

      $contratos{$nContrato} = $estado."-".$monto;
      #print "exito ".$ppiFiltrado{$nContrato}."\n";
    }
  }

  close (CONTRATOS);

  return %contratos;   
}


sub realizarConsulta{

  my %ppiFiltrado = &filtrarArchivoMaestro(@_);

  print "CONSULTAAA!!\n";
  foreach my $key (keys(%ppiFiltrado)) {
    print $key." ".$ppiFiltrado{$key}."\n";
  }

  print "Presione Enter para continuar";
  my $enter = <STDIN>;
}


sub menu{

  my $salir = 0;
  my $grabarListados = 0;   
  my $grabarModificaciones = 0;

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
  if (rand() < 0.1) { print "Hasta la vista!\n"; }
}

# Bloque principal.
&validarEntorno();
&menu();
#($pais,$sistema,$anio,$mes) = &cargarParametrosDeConsulta();
#&realizarConsulta($pais,$sistema,$anio,$mes);


