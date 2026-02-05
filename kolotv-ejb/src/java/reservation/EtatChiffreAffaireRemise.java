package reservation;

import bean.CGenUtil;
import utilitaire.UtilDB;
import utilitaire.Utilitaire;
import utils.CalendarUtil;

import java.sql.Connection;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.Duration;
import java.util.*;

/**
 * Classe pour gérer le chiffre d'affaires avec remise par tranche horaire
 * Tranches de 00:00 à 23:00 (24 tranches de 1h)
 * Utilise (montantTtc - montantRemise) pour le calcul
 * Le CA est réparti proportionnellement si une diffusion chevauche plusieurs tranches
 */
public class EtatChiffreAffaireRemise {
    private String[] listeDate;
    private HashMap<String, Vector> reservations;
    private List<LocalTime[]> horaire;
    private HashMap<String, Double> totalParJour = new HashMap<>();
    private HashMap<String, Double> totalParTranche = new HashMap<>();
    private double totalSemaine = 0;
    
    private static final String TIME_FORMAT = "HH:mm";

    public EtatChiffreAffaireRemise(String idSupport, String idTypeService, String dtMin, String dtMax) throws Exception {
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
    
    /**
     * Calcule le montant proportionnel avec remise d'une réservation pour une tranche horaire donnée
     * @param res La réservation
     * @param trancheDebut Début de la tranche
     * @param trancheFin Fin de la tranche
     * @return Le montant proportionnel avec remise pour cette tranche
     */
    private double calculerMontantProportionnel(ReservationDetailsAvecDiffusion res, LocalTime trancheDebut, LocalTime trancheFin) {
        if (res.getHeure() == null || res.getDuree() == null) {
            return 0;
        }
        
        try {
            LocalTime heureDebut = LocalTime.parse(res.getHeure());
            long dureeSecondes = Long.parseLong(res.getDuree());
            
            // Montant avec remise = TTC - Remise
            double montantAvecRemise = res.getMontantTtc() - res.getMontantRemise();
            
            if (dureeSecondes <= 0) {
                // Si pas de durée, on attribue tout le montant à la tranche de départ
                if (isInTranche(heureDebut, trancheDebut, trancheFin)) {
                    return montantAvecRemise;
                }
                return 0;
            }
            
            LocalTime heureFin = heureDebut.plusSeconds(dureeSecondes);
            
            // Calculer le chevauchement entre la réservation et la tranche
            LocalTime debutChevauchement = heureDebut.isAfter(trancheDebut) ? heureDebut : trancheDebut;
            LocalTime finChevauchement = heureFin.isBefore(trancheFin) ? heureFin : trancheFin;
            
            // Vérifier s'il y a un chevauchement
            if (debutChevauchement.isBefore(finChevauchement) || debutChevauchement.equals(finChevauchement)) {
                // Durée du chevauchement en secondes
                long dureeChevauchement = Duration.between(debutChevauchement, finChevauchement).getSeconds();
                
                if (dureeChevauchement > 0) {
                    // Calculer le ratio et le montant proportionnel
                    double ratio = (double) dureeChevauchement / dureeSecondes;
                    return montantAvecRemise * ratio;
                }
            }
            
            return 0;
        } catch (Exception e) {
            // En cas d'erreur de parsing, retourner 0
            return 0;
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
     */
    private void calculerTotaux() {
        this.totalParJour = new HashMap<>();
        this.totalParTranche = new HashMap<>();
        this.totalSemaine = 0;

        // Initialiser les totaux par tranche
        for (LocalTime[] tranche : horaire) {
            String cleTranche = tranche[0].format(DateTimeFormatter.ofPattern(TIME_FORMAT));
            totalParTranche.put(cleTranche, 0.0);
        }

        // Calculer les totaux par jour et mettre à jour les totaux par tranche
        for (String dt : listeDate) {
            double montantJour = 0;
            Vector v = this.reservations.get(dt);
            if (v != null) {
                for (Object o : v) {
                    ReservationDetailsAvecDiffusion res = (ReservationDetailsAvecDiffusion) o;
                    // Montant avec remise = TTC - Remise
                    double montantTotal = res.getMontantTtc() - res.getMontantRemise();
                    montantJour += montantTotal;

                    // Répartir le montant proportionnellement entre les tranches
                    for (LocalTime[] tranche : horaire) {
                        double montantTranche = calculerMontantProportionnel(res, tranche[0], tranche[1]);
                        if (montantTranche > 0) {
                            String cleTranche = tranche[0].format(DateTimeFormatter.ofPattern(TIME_FORMAT));
                            double ancienTotal = totalParTranche.getOrDefault(cleTranche, 0.0);
                            totalParTranche.put(cleTranche, ancienTotal + montantTranche);
                        }
                    }
                }
            }
            totalParJour.put(dt, montantJour);
            totalSemaine += montantJour;
        }
    }

    public boolean checkTime(LocalTime time, LocalTime timeMin, LocalTime timeMax) {
        return (time.isAfter(timeMin) || time.equals(timeMin)) && time.isBefore(timeMax);
    }

    /**
     * Obtenir le chiffre d'affaires avec remise pour une tranche horaire et une date donnée
     * Avec répartition proportionnelle du CA
     */
    public double getChiffreAffaireByTime(LocalTime[] times, String date) {
        double montant = 0;
        Vector liste = this.getReservations().get(date);
        if (liste != null) {
            for (Object d : liste) {
                ReservationDetailsAvecDiffusion rd = (ReservationDetailsAvecDiffusion) d;
                montant += calculerMontantProportionnel(rd, times[0], times[1]);
            }
        }
        return montant;
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
}
