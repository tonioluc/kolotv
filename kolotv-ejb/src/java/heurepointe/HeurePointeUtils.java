package heurepointe;

import java.sql.Connection;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.Duration;
import java.time.format.DateTimeFormatter;
import utilitaire.UtilDB;

/**
 * Utilitaire pour le calcul des majorations liées aux heures de pointe
 * Gère les chevauchements de diffusion avec les heures de pointe
 * Prend en compte le jour de la semaine pour l'application des majorations
 * 
 * @author Copilot
 */
public class HeurePointeUtils {

    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm:ss");
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    /**
     * Calcule le prix avec majoration pour une diffusion qui peut chevaucher une heure de pointe
     * 
     * @param prixBase Le prix de base de la diffusion (total)
     * @param heureDebut L'heure de début de la diffusion (format HH:mm:ss)
     * @param dureeSecondes La durée de la diffusion en secondes
     * @param idSupport L'ID du support (peut être null)
     * @param c Connection à la base de données
     * @return Le prix avec majoration appliquée
     */
    public static double calculerPrixAvecMajoration(double prixBase, String heureDebut, long dureeSecondes, String idSupport, Connection c) throws Exception {
        return calculerPrixAvecMajoration(prixBase, heureDebut, dureeSecondes, idSupport, (LocalDate) null, c);
    }
    
    /**
     * Calcule le prix avec majoration pour une diffusion avec prise en compte du jour de la semaine
     * 
     * @param prixBase Le prix de base de la diffusion (total)
     * @param heureDebut L'heure de début de la diffusion (format HH:mm:ss)
     * @param dureeSecondes La durée de la diffusion en secondes
     * @param idSupport L'ID du support (peut être null)
     * @param date La date de la diffusion (pour vérifier le jour de la semaine)
     * @param c Connection à la base de données
     * @return Le prix avec majoration appliquée
     */
    public static double calculerPrixAvecMajoration(double prixBase, String heureDebut, long dureeSecondes, String idSupport, LocalDate date, Connection c) throws Exception {
        if (heureDebut == null || dureeSecondes <= 0) {
            return prixBase;
        }

        boolean estOuvert = false;
        try {
            if (c == null) {
                estOuvert = true;
                c = new UtilDB().GetConn();
            }

            LocalTime debut = LocalTime.parse(heureDebut, TIME_FORMATTER);
            LocalTime fin = debut.plusSeconds(dureeSecondes);
            
            // Récupérer les heures de pointe actives pour ce support et ce jour
            HeurePointe[] heuresPointe;
            if (date != null) {
                heuresPointe = HeurePointe.getHeuresPointeByDate(idSupport, date, c);
            } else {
                heuresPointe = HeurePointe.getHeuresPointeBySupport(idSupport, c);
            }
            
            if (heuresPointe == null || heuresPointe.length == 0) {
                return prixBase;
            }

            // Calculer le prix par seconde
            double prixParSeconde = prixBase / dureeSecondes;
            double prixTotal = 0;
            long dureeTraitee = 0;

            // Pour chaque heure de pointe, calculer la majoration
            for (HeurePointe hp : heuresPointe) {
                // Vérifier si l'heure de pointe s'applique à ce jour
                if (date != null && !hp.sAppliqueAuJour(date)) {
                    continue;
                }
                
                long dureeChevauchement = hp.calculerDureeChevauchement(debut, fin);
                
                if (dureeChevauchement > 0) {
                    // Prix avec majoration pour la partie chevauchante
                    double majoration = 1 + (hp.getPourcentageMajoration() / 100.0);
                    prixTotal += prixParSeconde * dureeChevauchement * majoration;
                    dureeTraitee += dureeChevauchement;
                }
            }

            // Prix normal pour la partie non chevauchante
            long dureeNormale = dureeSecondes - dureeTraitee;
            if (dureeNormale > 0) {
                prixTotal += prixParSeconde * dureeNormale;
            }

            return prixTotal;

        } finally {
            if (c != null && estOuvert) {
                c.close();
            }
        }
    }
    
    /**
     * Calcule le prix avec majoration avec date au format String
     * 
     * @param prixBase Le prix de base de la diffusion (total)
     * @param heureDebut L'heure de début de la diffusion (format HH:mm:ss)
     * @param dureeSecondes La durée de la diffusion en secondes
     * @param idSupport L'ID du support (peut être null)
     * @param dateStr La date au format dd/MM/yyyy
     * @param c Connection à la base de données
     * @return Le prix avec majoration appliquée
     */
    public static double calculerPrixAvecMajoration(double prixBase, String heureDebut, long dureeSecondes, String idSupport, String dateStr, Connection c) throws Exception {
        LocalDate date = null;
        if (dateStr != null && !dateStr.isEmpty()) {
            try {
                date = LocalDate.parse(dateStr, DATE_FORMATTER);
            } catch (Exception e) {
                // Si la date n'est pas parsable, on continue sans
            }
        }
        return calculerPrixAvecMajoration(prixBase, heureDebut, dureeSecondes, idSupport, date, c);
    }

    /**
     * Calcule la majoration totale pour une diffusion
     * 
     * @param prixBase Le prix de base de la diffusion
     * @param heureDebut L'heure de début de la diffusion
     * @param dureeSecondes La durée de la diffusion en secondes
     * @param idSupport L'ID du support
     * @param c Connection à la base de données
     * @return Le montant de la majoration (sans le prix de base)
     */
    public static double calculerMontantMajoration(double prixBase, String heureDebut, long dureeSecondes, String idSupport, Connection c) throws Exception {
        return calculerMontantMajoration(prixBase, heureDebut, dureeSecondes, idSupport, (LocalDate) null, c);
    }
    
    /**
     * Calcule la majoration totale pour une diffusion avec prise en compte du jour
     * 
     * @param prixBase Le prix de base de la diffusion
     * @param heureDebut L'heure de début de la diffusion
     * @param dureeSecondes La durée de la diffusion en secondes
     * @param idSupport L'ID du support
     * @param date La date de la diffusion
     * @param c Connection à la base de données
     * @return Le montant de la majoration (sans le prix de base)
     */
    public static double calculerMontantMajoration(double prixBase, String heureDebut, long dureeSecondes, String idSupport, LocalDate date, Connection c) throws Exception {
        double prixAvecMajoration = calculerPrixAvecMajoration(prixBase, heureDebut, dureeSecondes, idSupport, date, c);
        return prixAvecMajoration - prixBase;
    }
    
    /**
     * Calcule la majoration totale pour une diffusion avec date au format String
     */
    public static double calculerMontantMajoration(double prixBase, String heureDebut, long dureeSecondes, String idSupport, String dateStr, Connection c) throws Exception {
        double prixAvecMajoration = calculerPrixAvecMajoration(prixBase, heureDebut, dureeSecondes, idSupport, dateStr, c);
        return prixAvecMajoration - prixBase;
    }

    /**
     * Vérifie si une diffusion chevauche au moins une heure de pointe
     * 
     * @param heureDebut L'heure de début de la diffusion
     * @param dureeSecondes La durée de la diffusion en secondes
     * @param idSupport L'ID du support
     * @param c Connection à la base de données
     * @return true si la diffusion chevauche une heure de pointe
     */
    public static boolean chevaucheHeurePointe(String heureDebut, long dureeSecondes, String idSupport, Connection c) throws Exception {
        return chevaucheHeurePointe(heureDebut, dureeSecondes, idSupport, (LocalDate) null, c);
    }
    
    /**
     * Vérifie si une diffusion chevauche au moins une heure de pointe pour une date donnée
     * 
     * @param heureDebut L'heure de début de la diffusion
     * @param dureeSecondes La durée de la diffusion en secondes
     * @param idSupport L'ID du support
     * @param date La date de la diffusion
     * @param c Connection à la base de données
     * @return true si la diffusion chevauche une heure de pointe
     */
    public static boolean chevaucheHeurePointe(String heureDebut, long dureeSecondes, String idSupport, LocalDate date, Connection c) throws Exception {
        if (heureDebut == null || dureeSecondes <= 0) {
            return false;
        }

        boolean estOuvert = false;
        try {
            if (c == null) {
                estOuvert = true;
                c = new UtilDB().GetConn();
            }

            LocalTime debut = LocalTime.parse(heureDebut, TIME_FORMATTER);
            LocalTime fin = debut.plusSeconds(dureeSecondes);

            HeurePointe[] heuresPointe;
            if (date != null) {
                heuresPointe = HeurePointe.getHeuresPointeByDate(idSupport, date, c);
            } else {
                heuresPointe = HeurePointe.getHeuresPointeBySupport(idSupport, c);
            }
            
            if (heuresPointe != null) {
                for (HeurePointe hp : heuresPointe) {
                    if (date != null && !hp.sAppliqueAuJour(date)) {
                        continue;
                    }
                    if (hp.chevaucheHeurePointe(debut, fin)) {
                        return true;
                    }
                }
            }
            
            return false;

        } finally {
            if (c != null && estOuvert) {
                c.close();
            }
        }
    }
    
    /**
     * Vérifie si une diffusion chevauche une heure de pointe avec date au format String
     */
    public static boolean chevaucheHeurePointe(String heureDebut, long dureeSecondes, String idSupport, String dateStr, Connection c) throws Exception {
        LocalDate date = null;
        if (dateStr != null && !dateStr.isEmpty()) {
            try {
                date = LocalDate.parse(dateStr, DATE_FORMATTER);
            } catch (Exception e) {
                // Si la date n'est pas parsable, on continue sans
            }
        }
        return chevaucheHeurePointe(heureDebut, dureeSecondes, idSupport, date, c);
    }

    /**
     * Calcule les détails de la majoration pour une diffusion
     * Utile pour afficher le détail du calcul à l'utilisateur
     * 
     * @param prixBase Le prix de base de la diffusion
     * @param heureDebut L'heure de début de la diffusion
     * @param dureeSecondes La durée de la diffusion en secondes
     * @param idSupport L'ID du support
     * @param c Connection à la base de données
     * @return Un objet DetailMajoration contenant tous les détails du calcul
     */
    public static DetailMajoration calculerDetailMajoration(double prixBase, String heureDebut, long dureeSecondes, String idSupport, Connection c) throws Exception {
        return calculerDetailMajoration(prixBase, heureDebut, dureeSecondes, idSupport, (LocalDate) null, c);
    }
    
    /**
     * Calcule les détails de la majoration pour une diffusion avec prise en compte du jour
     * 
     * @param prixBase Le prix de base de la diffusion
     * @param heureDebut L'heure de début de la diffusion
     * @param dureeSecondes La durée de la diffusion en secondes
     * @param idSupport L'ID du support
     * @param date La date de la diffusion
     * @param c Connection à la base de données
     * @return Un objet DetailMajoration contenant tous les détails du calcul
     */
    public static DetailMajoration calculerDetailMajoration(double prixBase, String heureDebut, long dureeSecondes, String idSupport, LocalDate date, Connection c) throws Exception {
        DetailMajoration detail = new DetailMajoration();
        detail.setPrixBase(prixBase);
        detail.setDureeTotale(dureeSecondes);
        detail.setDateDiffusion(date);

        if (heureDebut == null || dureeSecondes <= 0) {
            detail.setPrixFinal(prixBase);
            return detail;
        }

        boolean estOuvert = false;
        try {
            if (c == null) {
                estOuvert = true;
                c = new UtilDB().GetConn();
            }

            LocalTime debut = LocalTime.parse(heureDebut, TIME_FORMATTER);
            LocalTime fin = debut.plusSeconds(dureeSecondes);

            HeurePointe[] heuresPointe;
            if (date != null) {
                heuresPointe = HeurePointe.getHeuresPointeByDate(idSupport, date, c);
            } else {
                heuresPointe = HeurePointe.getHeuresPointeBySupport(idSupport, c);
            }
            
            double prixParSeconde = prixBase / dureeSecondes;
            double prixTotal = 0;
            long dureeEnHeurePointe = 0;
            double montantMajoration = 0;

            if (heuresPointe != null && heuresPointe.length > 0) {
                for (HeurePointe hp : heuresPointe) {
                    // Vérifier si l'heure de pointe s'applique à ce jour
                    if (date != null && !hp.sAppliqueAuJour(date)) {
                        continue;
                    }
                    
                    long dureeChevauchement = hp.calculerDureeChevauchement(debut, fin);
                    
                    if (dureeChevauchement > 0) {
                        double majoration = hp.getPourcentageMajoration() / 100.0;
                        double prixPartie = prixParSeconde * dureeChevauchement;
                        double majorationPartie = prixPartie * majoration;
                        
                        prixTotal += prixPartie + majorationPartie;
                        dureeEnHeurePointe += dureeChevauchement;
                        montantMajoration += majorationPartie;
                        
                        detail.addDetailHeurePointe(hp.getDesignation(), hp.getPourcentageMajoration(), 
                                                   dureeChevauchement, majorationPartie, hp.getJourSemaineLib());
                    }
                }
            }

            // Ajouter le prix normal pour la partie hors heure de pointe
            long dureeNormale = dureeSecondes - dureeEnHeurePointe;
            if (dureeNormale > 0) {
                prixTotal += prixParSeconde * dureeNormale;
            }

            detail.setDureeEnHeurePointe(dureeEnHeurePointe);
            detail.setDureeNormale(dureeNormale);
            detail.setMontantMajoration(montantMajoration);
            detail.setPrixFinal(prixTotal);

            return detail;

        } finally {
            if (c != null && estOuvert) {
                c.close();
            }
        }
    }
    
    /**
     * Calcule les détails de la majoration avec date au format String
     */
    public static DetailMajoration calculerDetailMajoration(double prixBase, String heureDebut, long dureeSecondes, String idSupport, String dateStr, Connection c) throws Exception {
        LocalDate date = null;
        if (dateStr != null && !dateStr.isEmpty()) {
            try {
                date = LocalDate.parse(dateStr, DATE_FORMATTER);
            } catch (Exception e) {
                // Si la date n'est pas parsable, on continue sans
            }
        }
        return calculerDetailMajoration(prixBase, heureDebut, dureeSecondes, idSupport, date, c);
    }

    /**
     * Classe interne pour stocker les détails d'une majoration
     */
    public static class DetailMajoration {
        private double prixBase;
        private double prixFinal;
        private double montantMajoration;
        private long dureeTotale;
        private long dureeEnHeurePointe;
        private long dureeNormale;
        private LocalDate dateDiffusion;
        private java.util.List<DetailHeurePointe> detailsHeuresPointe = new java.util.ArrayList<>();

        // Getters et Setters
        public double getPrixBase() { return prixBase; }
        public void setPrixBase(double prixBase) { this.prixBase = prixBase; }
        
        public double getPrixFinal() { return prixFinal; }
        public void setPrixFinal(double prixFinal) { this.prixFinal = prixFinal; }
        
        public double getMontantMajoration() { return montantMajoration; }
        public void setMontantMajoration(double montantMajoration) { this.montantMajoration = montantMajoration; }
        
        public long getDureeTotale() { return dureeTotale; }
        public void setDureeTotale(long dureeTotale) { this.dureeTotale = dureeTotale; }
        
        public long getDureeEnHeurePointe() { return dureeEnHeurePointe; }
        public void setDureeEnHeurePointe(long dureeEnHeurePointe) { this.dureeEnHeurePointe = dureeEnHeurePointe; }
        
        public long getDureeNormale() { return dureeNormale; }
        public void setDureeNormale(long dureeNormale) { this.dureeNormale = dureeNormale; }
        
        public LocalDate getDateDiffusion() { return dateDiffusion; }
        public void setDateDiffusion(LocalDate dateDiffusion) { this.dateDiffusion = dateDiffusion; }
        
        public java.util.List<DetailHeurePointe> getDetailsHeuresPointe() { return detailsHeuresPointe; }
        
        public void addDetailHeurePointe(String designation, double pourcentage, long duree, double montant) {
            detailsHeuresPointe.add(new DetailHeurePointe(designation, pourcentage, duree, montant, null));
        }
        
        public void addDetailHeurePointe(String designation, double pourcentage, long duree, double montant, String jourSemaine) {
            detailsHeuresPointe.add(new DetailHeurePointe(designation, pourcentage, duree, montant, jourSemaine));
        }

        /**
         * Vérifie si la diffusion a été majorée
         */
        public boolean estMajore() {
            return montantMajoration > 0;
        }

        /**
         * Retourne le pourcentage de majoration effectif
         */
        public double getPourcentageMajorationEffectif() {
            if (prixBase == 0) return 0;
            return (montantMajoration / prixBase) * 100;
        }
        
        /**
         * Retourne le jour de la semaine de la diffusion
         */
        public String getJourSemaineDiffusion() {
            if (dateDiffusion == null) return null;
            return HeurePointe.getJourSemaineLibelle(dateDiffusion.getDayOfWeek().getValue());
        }
    }

    /**
     * Classe interne pour le détail d'une heure de pointe
     */
    public static class DetailHeurePointe {
        private String designation;
        private double pourcentage;
        private long duree;
        private double montant;
        private String jourSemaine;

        public DetailHeurePointe(String designation, double pourcentage, long duree, double montant, String jourSemaine) {
            this.designation = designation;
            this.pourcentage = pourcentage;
            this.duree = duree;
            this.montant = montant;
            this.jourSemaine = jourSemaine;
        }

        public String getDesignation() { return designation; }
        public double getPourcentage() { return pourcentage; }
        public long getDuree() { return duree; }
        public double getMontant() { return montant; }
        public String getJourSemaine() { return jourSemaine; }
    }
}
