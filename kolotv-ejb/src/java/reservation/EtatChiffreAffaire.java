package reservation;

import bean.CGenUtil;
import heurepointe.HeurePointe;
import heurepointe.HeurePointeUtils;
import utilitaire.UtilDB;
import utilitaire.Utilitaire;
import utils.CalendarUtil;

import java.sql.Connection;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.Duration;
import java.util.*;

/**
 * Classe pour gérer l'état du chiffre d'affaires par tranche horaire
 * Tranches de 00:00 à 23:00 (24 tranches de 1h)
 * Le CA est réparti proportionnellement si une diffusion chevauche plusieurs tranches
 * Supporte les majorations d'heures de pointe avec prise en compte du jour de la semaine
 */
public class EtatChiffreAffaire {
    private String[] listeDate;
    private HashMap<String, Vector> reservations;
    private List<LocalTime[]> horaire;
    private HashMap<String, Double> totalParJour = new HashMap<>();
    private HashMap<String, Double> totalParTranche = new HashMap<>();
    private HashMap<String, Double> totalMajorationParJour = new HashMap<>();  // Nouveau: total des majorations par jour
    private double totalSemaine = 0;
    private double totalMajorationSemaine = 0;  // Nouveau: total des majorations sur la semaine
    private boolean inclureMajorations = true; // Par défaut, inclure les majorations d'heures de pointe
    
    private static final String TIME_FORMAT = "HH:mm";
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    public EtatChiffreAffaire(String idSupport, String idTypeService, String dtMin, String dtMax) throws Exception {
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            this.setListeDate(dtMin, dtMax);
            // Générer les 24 tranches horaires (00:00-01:00, 01:00-02:00, ..., 23:00-23:59)
            this.horaire = CalendarUtil.generateTimeIntervalsOfDay(60);
            this.setReservations(idSupport, idTypeService, dtMin, dtMax, c);
            this.calculerTotaux();
        } catch (Exception e) {
            throw e;
        } finally {
            if (c != null) c.close();
        }
    }

    public String[] getListeDate() {
        return listeDate;
    }

    public void setListeDate(String dtMin, String dtMax) {
        int day = Utilitaire.diffJourDaty(dtMax, dtMin);
        String[] liste = new String[day];
        for (int i = 0; i < day; i++) {
            liste[i] = Utilitaire.formatterDaty(Utilitaire.ajoutJourDate(dtMin, i));
        }
        this.listeDate = liste;
    }

    public HashMap<String, Vector> getReservations() {
        return reservations;
    }

    public void setReservations(String idSupport, String idTypeService, String dMin, String dMax, Connection c) throws Exception {
        ReservationDetailsAvecDiffusion res = new ReservationDetailsAvecDiffusion();
        if (idSupport != null && !idSupport.isEmpty()) {
            res.setIdSupport(idSupport);
        }
        if (idTypeService != null && !idTypeService.isEmpty()) {
            res.setCategorieproduit(idTypeService);
        }
        if (dMin == null || dMin.compareToIgnoreCase("") == 0) {
            dMin = Utilitaire.formatterDaty(Utilitaire.getDebutSemaine(Utilitaire.dateDuJourSql()));
        }
        String[] colInt = {"daty"};
        String[] valInt = {dMin, dMax};
        this.reservations = CGenUtil.rechercher2D(res, colInt, valInt, "daty", c, "");
    }

    public List<LocalTime[]> getHoraire() {
        return horaire;
    }

    public void setHoraire(List<LocalTime[]> horaire) {
        this.horaire = horaire;
    }

    public boolean isInclureMajorations() {
        return inclureMajorations;
    }

    public void setInclureMajorations(boolean inclureMajorations) {
        this.inclureMajorations = inclureMajorations;
    }
    
    /**
     * Calcule le montant proportionnel d'une réservation pour une tranche horaire donnée
     * Prend en compte les majorations d'heures de pointe si activé
     * @param res La réservation
     * @param trancheDebut Début de la tranche
     * @param trancheFin Fin de la tranche
     * @return Le montant proportionnel pour cette tranche (avec majoration si applicable)
     */
    private double calculerMontantProportionnel(ReservationDetailsAvecDiffusion res, LocalTime trancheDebut, LocalTime trancheFin) {
        return calculerMontantProportionnel(res, trancheDebut, trancheFin, null);
    }
    
    /**
     * Calcule le montant proportionnel d'une réservation pour une tranche horaire donnée
     * Prend en compte les majorations d'heures de pointe si activé et le jour de la semaine
     * @param res La réservation
     * @param trancheDebut Début de la tranche
     * @param trancheFin Fin de la tranche
     * @param dateDiffusion La date de la diffusion (pour le jour de la semaine)
     * @return Le montant proportionnel pour cette tranche (avec majoration si applicable)
     */
    private double calculerMontantProportionnel(ReservationDetailsAvecDiffusion res, LocalTime trancheDebut, LocalTime trancheFin, String dateDiffusion) {
        if (res.getHeure() == null || res.getDuree() == null) {
            return 0;
        }
        
        try {
            LocalTime heureDebut = LocalTime.parse(res.getHeure());
            long dureeSecondes = Long.parseLong(res.getDuree());
            
            if (dureeSecondes <= 0) {
                // Si pas de durée, on attribue tout le montant à la tranche de départ
                if (isInTranche(heureDebut, trancheDebut, trancheFin)) {
                    return res.getMontantTtc();
                }
                return 0;
            }
            
            LocalTime heureFin = heureDebut.plusSeconds(dureeSecondes);
            
            // Calculer le chevauchement entre la réservation et la tranche
            LocalTime debutChevauchement = heureDebut.isAfter(trancheDebut) ? heureDebut : trancheDebut;
            LocalTime finChevauchement = heureFin.isBefore(trancheFin) ? heureFin : trancheFin;
            
            // Gérer le cas où la diffusion dépasse minuit (cas rare mais possible)
            // Pour simplifier, on suppose que les diffusions ne dépassent pas minuit
            
            // Vérifier s'il y a un chevauchement
            if (debutChevauchement.isBefore(finChevauchement) || debutChevauchement.equals(finChevauchement)) {
                // Durée du chevauchement en secondes
                long dureeChevauchement = Duration.between(debutChevauchement, finChevauchement).getSeconds();
                
                if (dureeChevauchement > 0) {
                    // Calculer le ratio et le montant proportionnel de base
                    double prixParSeconde = res.getMontantTtc() / dureeSecondes;
                    double montantBase = prixParSeconde * dureeChevauchement;
                    
                    // Si les majorations sont activées, calculer avec les heures de pointe
                    if (inclureMajorations) {
                        // Convertir la date String en LocalDate
                        LocalDate date = null;
                        if (dateDiffusion != null && !dateDiffusion.isEmpty()) {
                            try {
                                date = LocalDate.parse(dateDiffusion, DATE_FORMATTER);
                            } catch (Exception e) {
                                // Ignorer si la date n'est pas parsable
                            }
                        }
                        return calculerMontantAvecMajorationPourTranche(
                            prixParSeconde, debutChevauchement, finChevauchement, 
                            dureeChevauchement, res.getIdSupport(), date);
                    }
                    
                    return montantBase;
                }
            }
            
            return 0;
        } catch (Exception e) {
            // En cas d'erreur de parsing, retourner 0
            return 0;
        }
    }

    /**
     * Calcule le montant avec majorations d'heures de pointe pour une portion de tranche
     * Prend en compte le jour de la semaine
     * @param prixParSeconde Le prix par seconde de la diffusion
     * @param debutChevauchement Début du chevauchement dans la tranche
     * @param finChevauchement Fin du chevauchement dans la tranche
     * @param dureeChevauchement Durée totale du chevauchement en secondes
     * @param idSupport ID du support
     * @param dateDiffusion La date de la diffusion (pour le jour de la semaine)
     * @return Le montant avec majoration appliquée
     */
    private double calculerMontantAvecMajorationPourTranche(double prixParSeconde, 
            LocalTime debutChevauchement, LocalTime finChevauchement, 
            long dureeChevauchement, String idSupport, LocalDate dateDiffusion) {
        
        Connection c = null;
        try {
            c = new UtilDB().GetConn();
            
            // Récupérer les heures de pointe en fonction de la date
            HeurePointe[] heuresPointe;
            if (dateDiffusion != null) {
                heuresPointe = HeurePointe.getHeuresPointeByDate(idSupport, dateDiffusion, c);
            } else {
                heuresPointe = HeurePointe.getHeuresPointeBySupport(idSupport, c);
            }
            
            if (heuresPointe == null || heuresPointe.length == 0) {
                return prixParSeconde * dureeChevauchement;
            }
            
            double montantFinal = 0;
            long dureeTraitee = 0;
            
            for (HeurePointe hp : heuresPointe) {
                // Vérifier si l'heure de pointe s'applique à ce jour
                if (dateDiffusion != null && !hp.sAppliqueAuJour(dateDiffusion)) {
                    continue;
                }
                
                long dureeEnHeurePointe = hp.calculerDureeChevauchement(debutChevauchement, finChevauchement);
                
                if (dureeEnHeurePointe > 0) {
                    double majoration = 1 + (hp.getPourcentageMajoration() / 100.0);
                    montantFinal += prixParSeconde * dureeEnHeurePointe * majoration;
                    dureeTraitee += dureeEnHeurePointe;
                }
            }
            
            // Ajouter la partie non majorée
            long dureeNormale = dureeChevauchement - dureeTraitee;
            if (dureeNormale > 0) {
                montantFinal += prixParSeconde * dureeNormale;
            }
            
            return montantFinal;
            
        } catch (Exception e) {
            // En cas d'erreur, retourner le montant de base
            return prixParSeconde * dureeChevauchement;
        } finally {
            if (c != null) {
                try { c.close(); } catch (Exception ex) { }
            }
        }
    }
    
    /**
     * Vérifie si une heure est dans une tranche (début inclus, fin exclue)
     */
    private boolean isInTranche(LocalTime heure, LocalTime trancheDebut, LocalTime trancheFin) {
        return (heure.equals(trancheDebut) || heure.isAfter(trancheDebut)) && heure.isBefore(trancheFin);
    }
    
    /**
     * Vérifie si une réservation chevauche une tranche horaire
     */
    private boolean chevaucheTrache(ReservationDetailsAvecDiffusion res, LocalTime trancheDebut, LocalTime trancheFin) {
        if (res.getHeure() == null) {
            return false;
        }
        
        try {
            LocalTime heureDebut = LocalTime.parse(res.getHeure());
            long dureeSecondes = 0;
            if (res.getDuree() != null) {
                dureeSecondes = Long.parseLong(res.getDuree());
            }
            
            LocalTime heureFin = heureDebut.plusSeconds(dureeSecondes);
            
            // La réservation chevauche la tranche si :
            // - Elle commence avant la fin de la tranche ET
            // - Elle se termine après le début de la tranche
            return heureDebut.isBefore(trancheFin) && heureFin.isAfter(trancheDebut);
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Calculer tous les totaux : par jour, par tranche et total semaine
     * Avec répartition proportionnelle du CA entre les tranches
     * Inclut le calcul des majorations d'heures de pointe par jour
     */
    private void calculerTotaux() {
        this.totalParJour = new HashMap<>();
        this.totalParTranche = new HashMap<>();
        this.totalMajorationParJour = new HashMap<>();
        this.totalSemaine = 0;
        this.totalMajorationSemaine = 0;

        // Initialiser les totaux par tranche
        for (LocalTime[] tranche : horaire) {
            String cleTranche = tranche[0].format(DateTimeFormatter.ofPattern(TIME_FORMAT));
            totalParTranche.put(cleTranche, 0.0);
        }

        // Calculer les totaux par jour et mettre à jour les totaux par tranche
        for (String dt : listeDate) {
            double montantJourBase = 0;
            double montantMajorationJour = 0;
            Vector v = this.reservations.get(dt);
            if (v != null) {
                for (Object o : v) {
                    ReservationDetailsAvecDiffusion res = (ReservationDetailsAvecDiffusion) o;
                    double montantTtcBase = res.getMontantTtc();
                    montantJourBase += montantTtcBase;

                    // Calculer le montant de majoration pour cette réservation
                    double montantAvecMajoration = 0;
                    
                    // Répartir le montant proportionnellement entre les tranches
                    for (LocalTime[] tranche : horaire) {
                        double montantTranche = calculerMontantProportionnel(res, tranche[0], tranche[1], dt);
                        montantAvecMajoration += montantTranche;
                        if (montantTranche > 0) {
                            String cleTranche = tranche[0].format(DateTimeFormatter.ofPattern(TIME_FORMAT));
                            double ancienTotal = totalParTranche.getOrDefault(cleTranche, 0.0);
                            totalParTranche.put(cleTranche, ancienTotal + montantTranche);
                        }
                    }
                    
                    // Calculer la majoration
                    double majorationCetteDiffusion = montantAvecMajoration - montantTtcBase;
                    if (majorationCetteDiffusion > 0) {
                        montantMajorationJour += majorationCetteDiffusion;
                    }
                }
            }
            totalParJour.put(dt, montantJourBase);
            totalMajorationParJour.put(dt, montantMajorationJour);
            totalSemaine += montantJourBase;
            totalMajorationSemaine += montantMajorationJour;
        }
    }

    public boolean checkTime(LocalTime time, LocalTime timeMin, LocalTime timeMax) {
        return (time.isAfter(timeMin) || time.equals(timeMin)) && time.isBefore(timeMax);
    }

    /**
     * Obtenir le chiffre d'affaires pour une tranche horaire et une date donnée
     * Avec répartition proportionnelle du CA
     */
    public double getChiffreAffaireByTime(LocalTime[] times, String date) {
        double montant = 0;
        Vector liste = this.getReservations().get(date);
        if (liste != null) {
            for (Object d : liste) {
                ReservationDetailsAvecDiffusion rd = (ReservationDetailsAvecDiffusion) d;
                montant += calculerMontantProportionnel(rd, times[0], times[1], date);
            }
        }
        return montant;
    }
    
    /**
     * Obtenir le chiffre d'affaires avec majoration pour une tranche horaire et une date donnée
     */
    public double getChiffreAffaireAvecMajorationByTime(LocalTime[] times, String date) {
        return getChiffreAffaireByTime(times, date); // Déjà inclut la majoration si activée
    }
    
    /**
     * Obtenir le montant de majoration pour une tranche horaire et une date donnée
     */
    public double getMajorationByTime(LocalTime[] times, String date) {
        double montantAvecMajoration = 0;
        double montantSans = 0;
        Vector liste = this.getReservations().get(date);
        if (liste != null) {
            // Temporairement désactiver les majorations pour calculer le montant de base
            boolean oldValue = this.inclureMajorations;
            
            for (Object d : liste) {
                ReservationDetailsAvecDiffusion rd = (ReservationDetailsAvecDiffusion) d;
                montantAvecMajoration += calculerMontantProportionnel(rd, times[0], times[1], date);
            }
            
            this.inclureMajorations = false;
            for (Object d : liste) {
                ReservationDetailsAvecDiffusion rd = (ReservationDetailsAvecDiffusion) d;
                montantSans += calculerMontantProportionnel(rd, times[0], times[1], date);
            }
            this.inclureMajorations = oldValue;
        }
        return montantAvecMajoration - montantSans;
    }

    /**
     * Obtenir les réservations qui chevauchent une tranche horaire pour une date donnée
     */
    public ReservationDetailsAvecDiffusion[] getReservationsByTime(LocalTime[] times, String date) {
        List<ReservationDetailsAvecDiffusion> res = new ArrayList<>();
        Vector liste = this.getReservations().get(date);
        if (liste != null) {
            for (Object d : liste) {
                ReservationDetailsAvecDiffusion rd = (ReservationDetailsAvecDiffusion) d;
                if (chevaucheTrache(rd, times[0], times[1])) {
                    res.add(rd);
                }
            }
        }
        return res.toArray(new ReservationDetailsAvecDiffusion[0]);
    }

    /**
     * Obtenir le nombre de réservations qui chevauchent une tranche horaire pour une date donnée
     */
    public int getNombreReservationsByTime(LocalTime[] times, String date) {
        return getReservationsByTime(times, date).length;
    }

    public HashMap<String, Double> getTotalParJour() {
        return totalParJour;
    }

    public HashMap<String, Double> getTotalParTranche() {
        return totalParTranche;
    }

    public double getTotalSemaine() {
        return totalSemaine;
    }
    
    /**
     * Obtenir le total des majorations sur la semaine
     */
    public double getTotalMajorationSemaine() {
        return totalMajorationSemaine;
    }
    
    /**
     * Obtenir le total semaine avec majorations incluses
     */
    public double getTotalSemaineAvecMajoration() {
        return totalSemaine + totalMajorationSemaine;
    }

    /**
     * Obtenir le total pour une tranche horaire spécifique (toute la semaine)
     */
    public double getTotalTranche(LocalTime[] times) {
        String cleTranche = times[0].format(DateTimeFormatter.ofPattern(TIME_FORMAT));
        return totalParTranche.getOrDefault(cleTranche, 0.0);
    }

    /**
     * Obtenir le total pour un jour spécifique
     */
    public double getTotalJour(String date) {
        return totalParJour.getOrDefault(date, 0.0);
    }
    
    /**
     * Obtenir le total de majoration pour un jour spécifique
     */
    public double getTotalMajorationJour(String date) {
        return totalMajorationParJour.getOrDefault(date, 0.0);
    }
    
    /**
     * Obtenir le total avec majoration pour un jour spécifique
     */
    public double getTotalJourAvecMajoration(String date) {
        return getTotalJour(date) + getTotalMajorationJour(date);
    }
}
