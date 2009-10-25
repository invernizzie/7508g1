#! /usr/bin/perl


# Variables globales.
@PAISES = ("A", "C");

$T1_DIR = "../conf/T1.tab";
$T2_DIR = "../conf/T2.tab";

# Un separador interno para el script que no se pisa con separadores de las 
# tablas.
$SEPARADOR = "-LOL-";

# Los datos del archivo T1 en forma de hash:
# Clave = <pais>SEPARADOR<sistema>
# Valor = <separador de campo>SEPARADOR<separador decimal>
%T1;

# Los datos del archivo T2 en forma de hash:
# Clave = <pais>SEPARADOR<sistema>SEPARADOR<nro de orden>
# Valor = <nombre de campo>SEPARADOR<formato>SEPARADOR<flag utilización>
%T2;

# Campos necesarios en T2 (sin los cuales no se podría armar, inversamente a 
# este script, los archivos CONTRAT).
# Clave = Nombre de campo
# Valor = Índice del campo en los registros del archivo CONTRAT
%CAMPOS_T2_NECESARIOS = ("NO_CONTRAT",  3,
                         "DT_FLUX",     4,
                         "CD_STATCTB",  5,
                         "MT_CRD",      6,
                         "MT_IMPAGO",   7,
                         "MT_INDE",     8,
                         "MT_INNODE",   9,
                         "MT_OTRSUMDC", 10,
                         );

@ALFANUMS = ("A".."Z", "0".."9");

sub randInt {
  return int(rand() * $_[0]);
}

sub randStr {
  my $long = @_[0];
  my $ret = "";
  foreach my $n (1..$long) {
    $ret = $ret.$ALFANUMS[randInt($#ALFANUMS + 1)];
  }
  return $ret;
}

sub imprimirTabla {
  my %tabla = @_;
  foreach my $clave (keys(%tabla)) {
    print "$clave: ".$tabla{$clave}."\n";
  }
}


sub inicializarT1 {

  open (T1, $T1_DIR) || die die "No se pudo arir $T1_DIR\n";

  while (my $lineaT1 = <T1>) {
    chomp($lineaT1);
    my ($pais, $sistema, $sepCampo, $sepDecimal) = split("-", $lineaT1);
    my $clave = join($SEPARADOR, $pais, $sistema);
    my $valor = join($SEPARADOR, $sepCampo, $sepDecimal);
    $T1{$clave} = $valor;
  }
  
  #&imprimirTabla(%T1);
  close (T1);
}

sub inicializarT2 {

  open (T2, $T2_DIR) || die die "No se pudo arir $T2_DIR\n";
  
  my %paisesSist;
  
  while (my $lineaT2 = <T2>) {
    chomp($lineaT2);
    my ($pais, $sistema, $nombreCampo, $nOrden, $formato, $flagUtilizacion) = 
      split("-", $lineaT2);
    my $clave = join($SEPARADOR, $pais, $sistema, $nOrden);
    my $valor = join($SEPARADOR, $nombreCampo, $formato, $flagUtilizacion);
    $T2{$clave} = $valor;
    
    $paisesSist{$pais.$SEPARADOR.$sistema} = "";
  }
  
  # Valida que para cada par pais-sistema de la tabla T2 existan todos los 
  # campos necesarios.
  foreach my $paisSist (keys(%paisesSist)) {
    my ($pais, $sistema) = split($SEPARADOR, $paisSist);
    my %t2filtrada = &filtrarT2PorPaisSistema($pais, $sistema);
    my @clavesT2filtrada = keys(%t2filtrada);
    
    # Validad consecutividad de campos.
    foreach my $nCampo (1..($#clavesT2filtrada + 1)) {
      if (! exists($T2{$paisSist.$SEPARADOR.$nCampo})) {
        die "Tabla T2 malformada: Los campos para el pais $pais y sistema ".
            "$sistema no son consecutivos. Falta el campo $nCampo\n";
      }
    }
    
    # Valida campos necesarios.
    foreach my $campoNecesario (keys(%CAMPOS_T2_NECESARIOS)) {
      my $encontrado = 0;
      foreach my $nCampo (1..($#clavesT2filtrada + 1)) {
        my $clave = $paisSist.$SEPARADOR.$nCampo;
        my ($nombreCampo, $formato, $flagUtilizacion) = 
          split($SEPARADOR, $T2{$clave});
        if ($nombreCampo eq $campoNecesario && $flagUtilizacion) {
          $encontrado = 1;
        }
      }
      if (!$encontrado) {
        die "Tabla T2 malformada: No se encontró el campo necesario ".
            "$campoNecesario para el pais $pais y sistema $sistema\n o no está".
            " siendo utilizado\n"
      }
    } # end foreach $campoNecesario
  } # end foreach $paisSist
  
  #&imprimirTabla(%T2);
  close (T2);
}

sub filtrarT2PorPaisSistema {
  
  my ($pais, $sistema) = @_;
  my $patron = $pais.$SEPARADOR.$sistema;
  my %t2filtrada;
  
  foreach $clave (keys(%T2)) {
    if ($clave =~ $patron) {
      $t2filtrada{$clave} = $T2{$clave};
    }
  }
  
  return %t2filtrada;
}


sub generarArchivosDataOk {
  
  my $pais = @_[0];
  my $contratFilename = "CONTRAT.$pais";
  
  print "Procesando archivo de contratos $contratFilename\n";
  open (CONTRATOS, "$contratFilename") || 
    die "No se pudo arir $contratFilename\n";
  
  # Lee todo el archivo de contratos de una vez.
  my @lineasContratos = <CONTRATOS>;
  foreach my $linea (@lineasContratos) {
    chomp($linea);
  }
  
  my %contratosFiltrados = 
    &filtrarContratos($pais, @lineasContratos);
  
  foreach my $nombreArch (keys(%contratosFiltrados)) {
    my @lineasContratosFiltradas = 
      split("::", $contratosFiltrados{$nombreArch});
    &generarArchivoDataOk($nombreArch, @lineasContratosFiltradas);
  }
  
  close(CONTRATOS);
}

# A partir de un pais y todas las lineas de contratos para ese pais, genera un
# hash de la forma:
# Clave = nombre de achivo data ok = <pais>-<sistema>-<año>-<mes>
# Valor = lineas de contrato para el archivo data ok separadas por "::"
sub filtrarContratos {
  
  my $pais = @_[0];
  my @lineasContratos = @_[1..$#_];
  my %filtrados;
  
  foreach my $lineaContrato (@lineasContratos) {
    my @regContrato = split("-", $lineaContrato);
    my ($sistema, $anio, $mes) = @regContrato[0..2];
    my $nombreArchivo = join("-", $pais, $sistema, $anio, $mes);
    if (exists $filtrados{$nombreArchivo}) {
      $filtrados{$nombreArchivo} = 
        $filtrados{$nombreArchivo}."::".$lineaContrato;
    }
    else {
      $filtrados{$nombreArchivo} = $lineaContrato;
    }
  }
  
  return %filtrados;
  
}

sub generarArchivoDataOk {
  
  my $filename = @_[0];
  my @lineasContrato = @_[1..$#_];
  my ($pais, $sistema, $anio, $mes) = split("-", $filename);
  
  print "  Generando archivo $filename\n";
  open (ARCH, ">./ok/$filename") || die "No se pudo arir $filename\n";
  
  foreach my $lineaContrato (@lineasContrato) {
    my $lineaDataOk = &generarLineaDataOk($pais, $sistema, $lineaContrato);
    print ARCH "$lineaDataOk\n";
  }

  close (ARCH);
  
}

sub generarLineaDataOk {

  my ($pais, $sistema, $lineaContrato) = @_;
  
  my @regContrato = split("-", $lineaContrato);
  my ($sepCampo, $sepDecimal) = split($SEPARADOR, 
                                      $T1{$pais.$SEPARADOR.$sistema});
  
  my %t2filtrada = &filtrarT2PorPaisSistema($pais, $sistema);
  my @clavesT2filtrada = keys(%t2filtrada);
  
  # Genera cada campo del registro de data ok.
  my @regDataOk;
  foreach my $nCampo (1..($#clavesT2filtrada + 1)) {
    my $valorT2 = $T2{join($SEPARADOR, $pais, $sistema, $nCampo)};
    my ($nombreCampo, $formato, $flagUtilizacion) = split($SEPARADOR, $valorT2);
    
    my $valor;
    if (exists $CAMPOS_T2_NECESARIOS{$nombreCampo}) {
      # El campo sale del archivo de contratos.
      my $indice = $CAMPOS_T2_NECESARIOS{$nombreCampo};
      $valor = $regContrato[$indice];
      if ($nombreCampo eq "CD_STATCTB") {
        $valor = $valor eq "SANO" ? (rand() < 0.5 ? "SNA" : "SNIM")
                                  : (rand() < 0.5 ? "DTCA" : "DTXA");
      } else {
        $valor = &formatearValor($valor, $formato, $sepDecimal);
      }
    }
    else {
      $valor = &chamullarValor($formato, $sepDecimal);
    }
    $regDataOk[$nCampo - 1] = $valor;
  }
  
  return join ($sepCampo, @regDataOk);
}


sub formatearValor {
  my ($valor, $formato, $sepDecimal) = @_;
  
  if ($formato =~ "dd") {
    # Es una fecha.
    my ($dia, $mes, $anio) = split("/", $valor);
    my @fecha;
    if    ($formato =~ "ddmmyy") { @fecha = ($dia, $mes, $anio); }
    elsif ($formato =~ "yymmdd") { @fecha = ($anio, $mes, $dia); }
    else { die "Foramto de fecha desconocido\n"}
    my $sepFecha = ($formato =~ "10") ? "/" : "";
    $valor = join($sepFecha, @fecha);
    #print "fecha: $valor\n";
  }
  elsif ($formato =~ /\$/) {
    # Es un valor alfanumérico.
    my $long = substr($formato, 1, -1);
    $valor = substr($valor, 0, $long);
    #print "alfanum: \"$valor\", long $long\n";
  }
  elsif ($formato =~ "commax") {
    # Es un valor de coma flotante.
    my $formatoDecim = substr($formato, 6); # saca el "commax".
    my ($longEnt, $longDec) = split(/\./, $formatoDecim);
    my ($ent, $dec) = split(/\./, "$valor");
    $ent = substr("$ent", 0, $longEnt);
    $dec = substr("$dec", 0, $longDec);
    $valor = $dec == 0 ? $ent : join($sepDecimal, $ent, $dec);
    #print "decimal: $valor\n";
  }
  else { die "Formato $formato desconocido\n"; }
  
  
  return $valor;
}

sub chamullarValor {
  my ($formato, $sepDecimal) = @_;
  
  if ($formato =~ "dd") {
    # Es una fecha.
    my ($dia, $mes, $anio) = (&randInt(31) + 1, &randInt(12) + 1, 
                              &randInt(9) + 2000);
    my @fecha;
    if    ($formato =~ "ddmmyy") { @fecha = ($dia, $mes, $anio); }
    elsif ($formato =~ "yymmdd") { @fecha = ($anio, $mes, $dia); }
    else { die "Foramto de fecha desconocido\n"}
    my $sepFecha = ($formato =~ "10") ? "/" : "";
    $valor = join($sepFecha, @fecha);
    #print "RANDOM fecha: $valor\n";
  }
  elsif ($formato =~ /\$/) {
    # Es un valor alfanumérico.
    my $long = substr($formato, 1, -1);
    $valor = randStr($long);
    #print "RANDOM alfanum: \"$valor\", long $long\n";
  }
  elsif ($formato =~ "commax") {
    # Es un valor de coma flotante.
    my $formatoDecim = substr($formato, 6); # saca el "commax".
    my ($longEnt, $longDec) = split(/\./, $formatoDecim);
    my $rndLongEnt = (randInt($longEnt) + 1);
    my $rndLongDec = (randInt($longDec) + 1);
    my $ent = randInt(10 ** $rndLongEnt);
    my $dec = rand() < 0.5 ? 0 : randInt(10 ** $rndLongDec);
    $valor = $dec == 0 ? $ent : join($sepDecimal, $ent, $dec);
    #print "RANDOM decimal: $valor - $longEnt - $rndLongEnt -  $ent\n";
  }
  else { die "Formato $formato desconocido\n"; }
  
  return $valor;
}


# Bloque principal.
mkdir "./ok";
&inicializarT1();
&inicializarT2();
foreach my $pais (@PAISES) {
  &generarArchivosDataOk($pais);
}

