package reservation;

import bean.AdminGen;
import bean.CGenUtil;
import duree.DisponibiliteHeure;
import heurepointe.HeurePointe;
import heurepointe.HeurePointeUtils;
import utilitaire.ConstanteEtat;
import utilitaire.UtilDB;
import utilitaire.Utilitaire;
import utils.CalendarUtil;
import utils.ConstanteStation;

import java.sql.Connection;
import java.sql.Date;
import java.sql.SQLException;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

public class EtatReservationDetails {
    String[] listeDate;
    HashMap<String, Vector> reservations;
    List<LocalTime[]> horaire;
    HashMap<String,Double[]> total = new HashMap<>();
    int dureeDiffuser;
    public EtatReservationDetails(String idSupport,String idTypeService,String dtMin,String dtMax) throws Exception {
        Connection c=null;
        try {
            c = new UtilDB().GetConn();
            this.setListeDate(dtMin,dtMax);
            horaire = CalendarUtil.trierParReference(CalendarUtil.generateTimeIntervalsOfDay(60),LocalTime.now());
            this.setReservations(idSupport,idTypeService,dtMin,dtMax,c);
            this.setTotal();
        }
        catch (Exception e) {
            throw e;
        }
        finally {
            if(c!=null)c.close();
        }
    }

    public String[] getListeDate() {
        return listeDate;
    }

    public void setListeDate(String dtMin,String dtMax) {
//        if(Utilitaire.diffJourDaty(dtMax,dtMin)<0)throw new Exception("Date sup inferieur a date Inf");
        int day = Utilitaire.diffJourDaty(dtMax, dtMin);
        String liste[]=new String[day];
        for (int i = 0; i < day; i++) {
            liste[i]=Utilitaire.formatterDaty(Utilitaire.ajoutJourDate(dtMin,i))  ;
//            System.out.println(liste[i]);
        }
        this.listeDate = liste;
    }

    public HashMap<String, Vector> getReservations() {
        return reservations;
    }

    public void setReservations(String idSupport,String idTypeService,String dMin,String dMax,Connection c) throws Exception {
        ReservationDetailsAvecDiffusion res = new ReservationDetailsAvecDiffusion();
        if (idSupport!=null && !idSupport.isEmpty()) {
            res.setIdSupport(idSupport);
        }
        if (idTypeService!=null && !idTypeService.isEmpty()) {
            res.setCategorieproduit(idTypeService);
        }
        if(dMin==null||dMin.compareToIgnoreCase("")==0)dMin=Utilitaire.formatterDaty(Utilitaire.getDebutSemaine(Utilitaire.dateDuJourSql())) ;
        String[] colInt={"daty"};
        String[] valInt={dMin,dMax};
        this.reservations=CGenUtil.rechercher2D(res,colInt,valInt,"daty",c,"");
    }

    public List<LocalTime[]> getHoraire() {
        return horaire;
    }

    public void setHoraire(List<LocalTime[]> horaire) {
        this.horaire = horaire;
    }

    public HashMap<String, Double[]> getTotal() {
        return total;
    }

    public void setTotal() {
        // total[0] - Montant Total
        // total[1] - Duree de diffusion Total
        this.total = new HashMap<>();
        for (String dt : listeDate) {
            double montantTotal = 0;
            double dureeTotal = 0;
            Vector v = this.reservations.get(dt);
            if (v != null) {
                for (Object o:v){
                    ReservationDetailsAvecDiffusion res = (ReservationDetailsAvecDiffusion) o;
                    montantTotal += res.getMontantTtc();
                    if (res.getDuree()!=null) {
                        dureeTotal += Double.valueOf(res.getDuree());
                    }
                }
            }
            total.put(dt,new Double[]{montantTotal,dureeTotal});
        }

    }

    public boolean checkTime (LocalTime time,LocalTime time_min,LocalTime time_max) {
        if (((time.isAfter(time_min) || time.equals(time_min)) && (time.isBefore(time_max)))){
            return true;
        }
        return false;
    }

    /**
     * Vérifie si une réservation chevauche une tranche horaire
     * Une diffusion de 08:58-09:03 chevauchera les tranches 08:00-09:00 ET 09:00-10:00
     */
    public boolean chevaucheTrache(ReservationDetailsAvecDiffusion res, LocalTime trancheDebut, LocalTime trancheFin) {
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
     * Calcule la durée de diffusion effective dans une tranche horaire donnée
     * Retourne la durée en secondes qui chevauche réellement la tranche
     */
    public int calculerDureeEffectiveDansTranche(ReservationDetailsAvecDiffusion res, LocalTime trancheDebut, LocalTime trancheFin) {
        if (res.getHeure() == null || res.getDuree() == null) {
            return 0;
        }
        
        try {
            LocalTime heureDebut = LocalTime.parse(res.getHeure());
            long dureeSecondes = Long.parseLong(res.getDuree());
            
            if (dureeSecondes <= 0) {
                return 0;
            }
            
            LocalTime heureFin = heureDebut.plusSeconds(dureeSecondes);
            
            // Calculer le chevauchement entre la réservation et la tranche
            LocalTime debutChevauchement = heureDebut.isAfter(trancheDebut) ? heureDebut : trancheDebut;
            LocalTime finChevauchement = heureFin.isBefore(trancheFin) ? heureFin : trancheFin;
            
            // Vérifier s'il y a un chevauchement
            if (debutChevauchement.isBefore(finChevauchement) || debutChevauchement.equals(finChevauchement)) {
                // Durée du chevauchement en secondes
                long dureeChevauchement = java.time.Duration.between(debutChevauchement, finChevauchement).getSeconds();
                return (int) dureeChevauchement;
            }
            
            return 0;
        } catch (Exception e) {
            return 0;
        }
    }

    public ReservationDetailsAvecDiffusion [] getReservationByTime(LocalTime [] times,String date) throws Exception {
        List<ReservationDetailsAvecDiffusion> res = new ArrayList<>();
        Vector liste = this.getReservations().get(date);
        this.dureeDiffuser = 0;
        if (liste!=null){
            for (Object d : liste) {
                ReservationDetailsAvecDiffusion rd = (ReservationDetailsAvecDiffusion) d;
                // Utiliser la logique de chevauchement au lieu de vérifier seulement l'heure de début
                // Ainsi une diffusion de 08:58-09:03 apparaîtra dans les deux tranches 08:00-09:00 ET 09:00-10:00
                if (chevaucheTrache(rd, times[0], times[1])) {

                    if (rd.getEtatMere()>= ConstanteEtat.getEtatValider()){
                        if (rd.getDuree()!=null){
                            // Calculer la durée effective dans cette tranche (pas la durée totale)
                            this.dureeDiffuser += calculerDureeEffectiveDansTranche(rd, times[0], times[1]);
                        }
                    }
                    res.add(rd);
                }
            }
        }
        return res.toArray(new ReservationDetailsAvecDiffusion[]{});
    }

//    public ReservationDetailsAvecDiffusion checkReste (ReservationDetailsAvecDiffusion rd,LocalTime [] times) throws Exception {
//        ReservationDetailsAvecDiffusion result = null;
//        LocalTime heure = LocalTime.parse(rd.getHeure());
//        LocalTime heure_fin = heure.plusSeconds(Long.parseLong(rd.getDuree()));
//        int restDuree = (int) (CalendarUtil.getDuration(heure,heure_fin) - CalendarUtil.getDuration(times[0],times[1]));
//        if (restDuree>0){
//            result = new ReservationDetailsAvecDiffusion();
//            result.setDuree(String.valueOf(restDuree));
//            result.setHeure(times[1].format(DateTimeFormatter.ofPattern("HH:mm:ss")));
//            result.setDureeDiffusion(rd.getDureeDiffusion());
//            result.setHeureDiffusion(rd.getHeureDiffusion());
//            result.setIdSupport(rd.getIdSupport());
//            result.setMontantTtc(rd.getMontantTtc());
//            result.setEtatLib(rd.getEtatLib());
//            result.setEtatMere(rd.getEtatMere());
//            result.setIdMediaLib(rd.getIdMediaLib());
//            result.setLibelleproduit(rd.getLibelleproduit());
//            result.setEtat(rd.getEtat());
//        }
//        return result;
//    }

    public int getDureeDiffuser() {
        return dureeDiffuser;
    }

    public void setDureeDiffuser(int dureeDiffuser) {
        this.dureeDiffuser = dureeDiffuser;
    }

    public int getResteADiffuser(LocalTime [] times){
        int result = (int) (CalendarUtil.getDuration(times[0],times[1])-this.dureeDiffuser);
        if (result<0){
            result = 0;
        }
        return result;
    }

    /**
     * Calcule le montant avec majoration d'heure de pointe pour une réservation
     * Si la diffusion chevauche une heure de pointe, applique la majoration correspondante
     * @param res La réservation à calculer
     * @param c Connection à la base de données (peut être null)
     * @return Le montant avec majoration appliquée
     */
    public static double calculerMontantAvecMajoration(ReservationDetailsAvecDiffusion res, Connection c) throws Exception {
        if (res == null || res.getHeure() == null || res.getDuree() == null) {
            return res != null ? res.getMontantTtc() : 0;
        }
        
        try {
            long dureeSecondes = Long.parseLong(res.getDuree());
            if (dureeSecondes <= 0) {
                return res.getMontantTtc();
            }
            
            return HeurePointeUtils.calculerPrixAvecMajoration(
                res.getMontantTtc(),
                res.getHeure(),
                dureeSecondes,
                res.getIdSupport(),
                c
            );
        } catch (Exception e) {
            // En cas d'erreur, retourner le montant de base
            return res.getMontantTtc();
        }
    }

    /**
     * Calcule le montant proportionnel avec majoration d'heure de pointe
     * pour une partie d'une diffusion dans une tranche horaire donnée
     * @param res La réservation
     * @param trancheDebut Début de la tranche horaire
     * @param trancheFin Fin de la tranche horaire
     * @param c Connection à la base de données
     * @return Le montant proportionnel avec majoration pour cette tranche
     */
    public double calculerMontantProportionnelAvecMajoration(ReservationDetailsAvecDiffusion res, 
            LocalTime trancheDebut, LocalTime trancheFin, Connection c) throws Exception {
        
        if (res.getHeure() == null || res.getDuree() == null) {
            return 0;
        }
        
        boolean estOuvert = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                estOuvert = true;
            }
            
            LocalTime heureDebut = LocalTime.parse(res.getHeure());
            long dureeSecondes = Long.parseLong(res.getDuree());
            
            if (dureeSecondes <= 0) {
                return 0;
            }
            
            LocalTime heureFin = heureDebut.plusSeconds(dureeSecondes);
            
            // Calculer le chevauchement entre la réservation et la tranche
            LocalTime debutChevauchement = heureDebut.isAfter(trancheDebut) ? heureDebut : trancheDebut;
            LocalTime finChevauchement = heureFin.isBefore(trancheFin) ? heureFin : trancheFin;
            
            // Vérifier s'il y a un chevauchement
            if (!debutChevauchement.isBefore(finChevauchement) && !debutChevauchement.equals(finChevauchement)) {
                return 0;
            }
            
            long dureeChevauchement = java.time.Duration.between(debutChevauchement, finChevauchement).getSeconds();
            if (dureeChevauchement <= 0) {
                return 0;
            }
            
            // Prix de base par seconde
            double prixParSeconde = res.getMontantTtc() / dureeSecondes;
            double prixBasePartie = prixParSeconde * dureeChevauchement;
            
            // Récupérer les heures de pointe pour ce support
            HeurePointe[] heuresPointe = HeurePointe.getHeuresPointeBySupport(res.getIdSupport(), c);
            
            if (heuresPointe == null || heuresPointe.length == 0) {
                return prixBasePartie;
            }
            
            // Calculer la majoration pour la partie de cette tranche
            double montantFinal = 0;
            long dureeTraitee = 0;
            
            for (HeurePointe hp : heuresPointe) {
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
            
        } finally {
            if (c != null && estOuvert) {
                c.close();
            }
        }
    }

    /**
     * Vérifie si une réservation chevauche une heure de pointe
     * @param res La réservation à vérifier
     * @param c Connection à la base de données
     * @return true si la réservation chevauche une heure de pointe
     */
    public static boolean estEnHeurePointe(ReservationDetailsAvecDiffusion res, Connection c) throws Exception {
        if (res == null || res.getHeure() == null || res.getDuree() == null) {
            return false;
        }
        
        try {
            long dureeSecondes = Long.parseLong(res.getDuree());
            return HeurePointeUtils.chevaucheHeurePointe(
                res.getHeure(),
                dureeSecondes,
                res.getIdSupport(),
                c
            );
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Obtient les détails de la majoration pour une réservation
     * @param res La réservation
     * @param c Connection à la base de données
     * @return Les détails de la majoration
     */
    public static HeurePointeUtils.DetailMajoration getDetailMajoration(ReservationDetailsAvecDiffusion res, Connection c) throws Exception {
        if (res == null || res.getHeure() == null || res.getDuree() == null) {
            HeurePointeUtils.DetailMajoration detail = new HeurePointeUtils.DetailMajoration();
            detail.setPrixBase(res != null ? res.getMontantTtc() : 0);
            detail.setPrixFinal(res != null ? res.getMontantTtc() : 0);
            return detail;
        }
        
        long dureeSecondes = Long.parseLong(res.getDuree());
        return HeurePointeUtils.calculerDetailMajoration(
            res.getMontantTtc(),
            res.getHeure(),
            dureeSecondes,
            res.getIdSupport(),
            c
        );
    }
}
