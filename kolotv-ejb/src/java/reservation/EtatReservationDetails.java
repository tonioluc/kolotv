package reservation;

import bean.AdminGen;
import bean.CGenUtil;
import duree.DisponibiliteHeure;
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
    double caParHoraire; // CA généré pour la plage horaire courante
    HashMap<String, Double> totalCAParHoraire = new HashMap<>(); // CA par plage horaire (clé: heure début)
    double totalCAGeneral = 0; // Total CA pour toute la grille
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
        // total[0] - Montant Total (sera recalculé après getReservationByTime)
        // total[1] - Duree de diffusion Total
        this.total = new HashMap<>();
        this.totalCAGeneral = 0;
        for (String dt : listeDate) {
            double montantTotal = 0;
            double dureeTotal = 0;
            Vector v = this.reservations.get(dt);
            if (v != null) {
                for (Object o:v){
                    ReservationDetailsAvecDiffusion res = (ReservationDetailsAvecDiffusion) o;
                    // Le CA total par jour reste le même (somme des montants des réservations)
                    montantTotal += res.getMontantTtc();
                    this.totalCAGeneral += res.getMontantTtc();
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
     * Vérifie si une diffusion chevauche une plage horaire donnée
     * @param heureDebut Heure de début de la diffusion
     * @param heureFin Heure de fin de la diffusion
     * @param slotDebut Début de la plage horaire
     * @param slotFin Fin de la plage horaire
     * @return true si la diffusion chevauche la plage horaire
     */
    public boolean chevauchePlageHoraire(LocalTime heureDebut, LocalTime heureFin, LocalTime slotDebut, LocalTime slotFin) {
        // Une diffusion chevauche si elle ne se termine pas avant le début du slot
        // et ne commence pas après la fin du slot
        return !heureFin.isBefore(slotDebut) && !heureDebut.isAfter(slotFin) && heureFin.isAfter(slotDebut);
    }

    /**
     * Calcule la durée de chevauchement entre une diffusion et une plage horaire
     * @param heureDebut Heure de début de la diffusion
     * @param heureFin Heure de fin de la diffusion
     * @param slotDebut Début de la plage horaire
     * @param slotFin Fin de la plage horaire
     * @return Durée de chevauchement en secondes
     */
    public long getDureeChevauchement(LocalTime heureDebut, LocalTime heureFin, LocalTime slotDebut, LocalTime slotFin) {
        // Trouver le début effectif du chevauchement
        LocalTime debutEffectif = heureDebut.isAfter(slotDebut) ? heureDebut : slotDebut;
        // Trouver la fin effective du chevauchement
        LocalTime finEffective = heureFin.isBefore(slotFin) ? heureFin : slotFin;
        
        // Si pas de chevauchement, retourner 0
        if (debutEffectif.isAfter(finEffective) || debutEffectif.equals(finEffective)) {
            return 0;
        }
        
        return CalendarUtil.getDuration(debutEffectif, finEffective);
    }

    /**
     * Calcule le CA proportionnel pour une diffusion dans une plage horaire
     * @param rd La réservation
     * @param slotDebut Début de la plage horaire
     * @param slotFin Fin de la plage horaire
     * @return Le CA proportionnel
     */
    public double getCAProportionnel(ReservationDetailsAvecDiffusion rd, LocalTime slotDebut, LocalTime slotFin) {
        if (rd.getDuree() == null || rd.getDuree().isEmpty()) {
            return 0;
        }
        
        LocalTime heureDebut = LocalTime.parse(rd.getHeure());
        int dureeTotale = Integer.parseInt(rd.getDuree());
        LocalTime heureFin = heureDebut.plusSeconds(dureeTotale);
        
        long dureeChevauchement = getDureeChevauchement(heureDebut, heureFin, slotDebut, slotFin);
        
        if (dureeTotale <= 0 || dureeChevauchement <= 0) {
            return 0;
        }
        
        // Calculer le CA proportionnel
        double proportion = (double) dureeChevauchement / (double) dureeTotale;
        return rd.getMontantTtc() * proportion;
    }

    public ReservationDetailsAvecDiffusion [] getReservationByTime(LocalTime [] times,String date) throws Exception {
        List<ReservationDetailsAvecDiffusion> res = new ArrayList<>();
        Vector liste = this.getReservations().get(date);
        this.dureeDiffuser = 0;
        this.caParHoraire = 0;
        if (liste!=null){
            for (Object d : liste) {
                ReservationDetailsAvecDiffusion rd = (ReservationDetailsAvecDiffusion) d;
                LocalTime heureDebut = LocalTime.parse(rd.getHeure());
                
                // Calculer l'heure de fin de la diffusion
                LocalTime heureFin = heureDebut;
                if (rd.getDuree() != null && !rd.getDuree().isEmpty()) {
                    heureFin = heureDebut.plusSeconds(Long.parseLong(rd.getDuree()));
                }
                
                // Vérifier si la diffusion chevauche cette plage horaire
                if (chevauchePlageHoraire(heureDebut, heureFin, times[0], times[1])) {
                    if (rd.getEtatMere() >= ConstanteEtat.getEtatValider()) {
                        // Calculer la durée de chevauchement pour cette plage
                        long dureeChevauchement = getDureeChevauchement(heureDebut, heureFin, times[0], times[1]);
                        this.dureeDiffuser += dureeChevauchement;
                        
                        // Calculer le CA proportionnel basé sur le temps dans cette plage
                        double caProportionnel = getCAProportionnel(rd, times[0], times[1]);
                        this.caParHoraire += caProportionnel;
                    }
                    res.add(rd);
                }
            }
        }
        // Stocker le CA pour cette plage horaire
        String cleHoraire = times[0].toString() + "-" + date;
        totalCAParHoraire.put(cleHoraire, this.caParHoraire);
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

    public double getCaParHoraire() {
        return caParHoraire;
    }

    public void setCaParHoraire(double caParHoraire) {
        this.caParHoraire = caParHoraire;
    }

    public double getTotalCAGeneral() {
        return totalCAGeneral;
    }

    public void setTotalCAGeneral(double totalCAGeneral) {
        this.totalCAGeneral = totalCAGeneral;
    }

    public HashMap<String, Double> getTotalCAParHoraire() {
        return totalCAParHoraire;
    }

    public void setTotalCAParHoraire(HashMap<String, Double> totalCAParHoraire) {
        this.totalCAParHoraire = totalCAParHoraire;
    }

    // Calculer le total CA pour une plage horaire donnée (toutes les dates)
    public double getTotalCAForHoraire(LocalTime[] times) {
        double totalCA = 0;
        for (String date : listeDate) {
            String cle = times[0].toString() + "-" + date;
            Double ca = totalCAParHoraire.get(cle);
            if (ca != null) {
                totalCA += ca;
            }
        }
        return totalCA;
    }
}
