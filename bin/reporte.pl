#! /usr/bin/perl

use Switch;

sub validacionNula{

  return @_[0];
}

# TODO
sub validarPais{
  
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

sub validarMes{
  
  my $mes = int(@_[0]); 
  return $mes >= 1 && $mes <= 12 ? $mes : "";
}

sub cargaParametro{

  my $parametro = @_[0];
  my $validacion=@_[1];
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
  
  my $parametro = @_[0];
  my $validacion = @_[1];  
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

# Cargar parametros de consulta (Pais,Sistema, Anio y Mes)
sub cargarParametrosDeConsulta{

  my $pais = &cargaParametro("pais","validarPais");
  my $sistema = &cargaParametroOpcional("sistema","validarSistema");
  my $anio;
  my $mes;

  if ($anio = &cargaParametroOpcional("anio", "validarAnio")){
    $mes = &cargaParametroOpcional("mes", "validarMes");
  }
  
  @_[0] = $pais;
  @_[1] = $sistema;
  @_[2] = $anio;
  @_[3] = $mes;  
}

sub filtrarArchivoMaestro{

  my @registro;  
  my $fileName = "PPI.mae";
  my $monto;  
  my $nContrato;
  my $estado;
  my %ppiFiltrado;
  my $pais;
  my $sistema;
  my $mes;
  my $anio;

  my $filtroPais = @_[0];
  my $filtroSistema = @_[1];
  my $filtroAnio = @_[2];
  my $filtroMes = @_[3];
  
  open(PPI,$fileName);

  while ($linea = <PPI>){
   
    chomp($linea);
    @registro = split("-",$linea);
    $pais = $registro[0];
    $sistema = $registro[1];
    $anio = $registro[2];
    $mes = $registro[3];
    
    #@valor = ($pais, $sistema, $anio, $mes, $estado, $monto);
    #push(@maestro,join("-", @valor));

    # Filtros!
    if (!$filtroPais || $pais eq $filtroPais) {
      if (!$filtroSistema || $sistema eq $filtroSistema) {
        if (!$filtroAnio || $anio eq $filtroAnio) {
	  if (!$filtroMes || $mes eq $filtroMes) {
	    # El registro pasa todos los filtros!
	    $estado = $registro[6];
	    $nContrato = $registro[7];
	    # MT_RESTANTE = MT_CRD + MT_IMPAGO + MT_INDE - MT_OTRSUMDC
	    $monto = $registro[10] + $registro[11] + $registro[13] - $registro[14];

	    $ppiFiltrado{$nContrato} = $estado."-".$monto;
	    print "exito ".$ppiFiltrado{$nContrato}."\n";
          }
        }
      }
    }
  }

  close(PPI);
  #foreach $key (keys(%ppiFiltrado)) {
  #  print $key."  ".$ppiFiltrado{$key}."\n";
  #}


  return %ppiFiltrado;   
}


sub filtrarArchivoContratos{

  my @registro;  
  my $pais = @_[0];
  my $filtroSistema = @_[1];
  my $filtroAnio = @_[2];
  my $filtroMes = @_[3];
  my $fileName = "CONTRACT.$pais";
  my $monto;  
  my $nContrato;
  my $estado;
  my %contratos;
  
  my $sistema;
  my $mes;
  my $anio;

  
  open(CONTRATOS,$fileName);

  while ($linea = <CONTRATOS>){
   
    chomp($linea);
    @registro = split("-",$linea);
    $sistema = $registro[0];
    $anio = $registro[1];
    $mes = $registro[2];
    
    #@valor = ($pais, $sistema, $anio, $mes, $estado, $monto);
    #push(@maestro,join("-", @valor));

    # Filtros!
    if (!$filtroSistema || $sistema eq $filtroSistema) {
      if (!$filtroAnio || $anio eq $filtroAnio) {
	if (!$filtroMes || $mes eq $filtroMes) {
	  # El registro pasa todos los filtros!
	  $estado = $registro[6];
	  $nContrato = $registro[7];
	  # MT_RESTANTE = MT_CRD + MT_IMPAGO + MT_INDE - MT_OTRSUMDC
	  $monto = $registro[11]; 

	  $ppiFiltrado{$nContrato} = $estado."-".$monto;
	  print "exito ".$ppiFiltrado{$nContrato}."\n";
	}
      }
    }
  }

  
  #foreach $key (keys(%ppiFiltrado)) {
  #  print $key."  ".$ppiFiltrado{$key}."\n";
  #}


  return %ppiFiltrado;   
}

sub realizarConsulta{

  %ppiFiltrado = &filtrarArchivoMaestro(@_);

  return 0;
}

sub menu{

  my $salir = 0;
  my $grabarListados = 0;   
  my $grabarModificaciones = 0;

  while (!$salir){

    system("clear");
    print "Paramatros actuales de consulta, Pais: $pais - Sistema: $sistema - Anio: $anio - Mes: $mes\n";
    print "1- Cargar parametros de consulta.\n";
    print "2- ".($grabarListados ? "Desactivar" : "Activar")." grabacion de listados de consultas.\n";
    print "3- ".($grabarModificaciones ? "Desactivar" : "Activar")." grabacion de modificaciones de contratos.\n";
    print "4- Realizar consulta.\n";
    print "5- Salir.\n";
    print "Opcion: ";
    $opcion = <STDIN>;
    chomp($opcion);
    
    switch ($opcion) {
	
      case 1 {&cargarParametrosDeConsulta($pais,$sistema,$anio,$mes);}
      case 2 {$grabarListados = !$grabarListados}
      case 3 {$grabarModificaciones = !$grabarModificaciones}
      case 4 {&realizarConsulta($pais,$sistema,$anio,$mes)}
      case 5 {$salir=1}
    }
  }
}

# Bloque principal.
#&menu();
&cargarParametrosDeConsulta($pais,$sistema,$anio,$mes);
&realizarConsulta($pais,$sistema,$anio,$mes);