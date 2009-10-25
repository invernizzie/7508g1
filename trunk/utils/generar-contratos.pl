#! /usr/bin/perl


# Variables Globales.
@PAISES = ("A", "C");
@ESTADOS = ("SANO", "DUDOSO");
$PPI_DIR = "../data/mae/PPI.mae";
# El porcentaje de registros del PPI que se utilizan para generar los contratos.
$PCT_PPI = 0.8;
# el porcentaje de registros de contratos que tienen en mismo monto que el de 
# PPI.
$PCT_MISMO_MONTO = 0.5;

sub randInt {
  return int(rand() * $_[0]);
}

sub generarContratos {
  
  my $pais = $_[0];
  my $filename = "CONTRAT.$pais";
  
  print "Generando archivo de contratos $filename\n";
  
  open(PPI, $PPI_DIR) || die "No se pudo arir $PPI_DIR\n";
  open(CONTRATOS, ">$filename") || die "No se pudo arir $filename\n";
  
  while (my $lineaPpi = <PPI>) {
    
    chomp($lineaPpi);
    my @regPpi = split("-", $lineaPpi);
    
    my $suerte = rand() < $PCT_PPI;
    
    # Procesa solo los registros del mismo pais.
    if ($regPpi[0] eq $pais && $suerte) {
      
      my ($sis_id, $anio_id, $mes_id, $no_contrat, $dt_flux) = 
          @regPpi[1, 2, 3, 7, 8];
      
      # Formatea correctamente la fecha.
      # En el PPI aparecen como mmddyyyy.
      my ($fluxMes, $fluxDia, $fluxAnio) = split("/", $dt_flux);
      $dt_flux = sprintf("%02d/%02d/%04d", $fluxDia, $fluxMes, $fluxAnio);
      
      my $estado = $ESTADOS[&randInt($#ESTADOS + 1)];
      my ($mt_crd, $mt_impago, $mt_inde, $mt_innode, $mt_otrsumdc, 
          $mt_restante);
      
      my $mismoMonto = rand() < $PCT_MISMO_MONTO;
      
      if ($mismoMonto) {
        ($mt_crd, $mt_impago, $mt_inde, $mt_innode, $mt_otrsumdc) = 
            @regPpi[10, 11, 13, 12, 14];
        # Calculo de monto.
        $mt_restante = $mt_crd + $mt_impago + $mt_inde - $mt_otrsumdc;
      }
      else { 
        ($mt_impago, $mt_inde, $mt_innode, $mt_otrsumdc) = 
            (0, 0, 0, 0);
        $mt_restante = &randInt(100000) / 100.0;
        $mt_crd = $mt_restante;
      }
      my $dt_insert = sprintf("%02d/%02d/%04d", &randInt(31) + 1, 
                              &randInt(12) + 1, &randInt(9) + 2000);
      #TODO
      my $us_id = 0;
      
      my $linea = join("-", $sis_id, $anio_id, $mes_id, $no_contrat, $dt_flux, 
                       $estado, $mt_crd, $mt_impago, $mt_inde, $mt_innode, 
                       $mt_otrsumdc, $mt_restante, $dt_insert, $us_id);
      print CONTRATOS "$linea\n";
    }
  }
  close(PPI);
  close(CONTRATOS);
}


# Bloque principal.
foreach my $pais (@PAISES) {
  &generarContratos($pais);
}



