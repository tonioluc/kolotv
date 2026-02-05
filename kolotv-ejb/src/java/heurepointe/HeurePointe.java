package heurepointe;

import bean.CGenUtil;
import bean.ClassMAPTable;
import java.sql.Connection;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import utilitaire.UtilDB;

/**
 * Classe représentant une heure de pointe de majoration
 * Permet de définir une période horaire avec un pourcentage de majoration
 * applicable sur les prix de diffusion pour un jour de la semaine spécifique
 * 
 * @author Copilot
 */
public class HeurePointe extends ClassMAPTable {
    
    private String id;
    private String heureDebut;     // Format HH:mm:ss
    private String heureFin;       // Format HH:mm:ss
    private double pourcentageMajoration;  // Pourcentage de majoration (ex: 10 pour 10%)
    private String designation;
    private int etat;
    private String idSupport;      // Support concerné (optionnel, null = tous les supports)
    private int jourSemaine;       // Jour de la semaine (0=Tous, 1=Lundi, 2=Mardi, ..., 7=Dimanche)
    
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm:ss");
    
    // Constantes pour les jours de la semaine
    public static final int TOUS_LES_JOURS = 0;
    public static final int LUNDI = 1;
    public static final int MARDI = 2;
    public static final int MERCREDI = 3;
    public static final int JEUDI = 4;
    public static final int VENDREDI = 5;
    public static final int SAMEDI = 6;
    public static final int DIMANCHE = 7;

    public HeurePointe() {
        this.setNomTable("HEUREPOINTE");
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("HPT", "GETSEQ_HEUREPOINTE");
        this.setId(makePK(c));
    }

    // Getters et Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getHeureDebut() {
        return heureDebut;
    }

    public void setHeureDebut(String heureDebut) {
        this.heureDebut = heureDebut;
    }

    public String getHeureFin() {
        return heureFin;
    }

    public void setHeureFin(String heureFin) {
        this.heureFin = heureFin;
    }

    public double getPourcentageMajoration() {
        return pourcentageMajoration;
    }

    public void setPourcentageMajoration(double pourcentageMajoration) {
        this.pourcentageMajoration = pourcentageMajoration;
    }

    public String getDesignation() {
        return designation;
    }

    public void setDesignation(String designation) {
        this.designation = designation;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }

    public String getIdSupport() {
        return idSupport;
    }

    public void setIdSupport(String idSupport) {
        this.idSupport = idSupport;
    }

    public int getJourSemaine() {
        return jourSemaine;
    }

    public void setJourSemaine(int jourSemaine) {
        this.jourSemaine = jourSemaine;
    }
    
    /**
     * Retourne le libellé du jour de la semaine
     */
    public String getJourSemaineLib() {
        return getJourSemaineLibelle(this.jourSemaine);
    }
    
    /**
     * Retourne le libellé du jour de la semaine à partir de son numéro
     * @param jour Numéro du jour (0-7)
     * @return Libellé du jour
     */
    public static String getJourSemaineLibelle(int jour) {
        switch (jour) {
            case TOUS_LES_JOURS: return "Tous les jours";
            case LUNDI: return "Lundi";
            case MARDI: return "Mardi";
            case MERCREDI: return "Mercredi";
            case JEUDI: return "Jeudi";
            case VENDREDI: return "Vendredi";
            case SAMEDI: return "Samedi";
            case DIMANCHE: return "Dimanche";
            default: return "Inconnu";
        }
    }
    
    /**
     * Convertit un DayOfWeek Java en numéro de jour (1=Lundi à 7=Dimanche)
     */
    public static int dayOfWeekToJourSemaine(DayOfWeek dayOfWeek) {
        return dayOfWeek.getValue(); // 1=Lundi, 7=Dimanche (compatible avec notre convention)
    }
    
    /**
     * Vérifie si cette heure de pointe s'applique à une date donnée
     * @param date La date à vérifier
     * @return true si l'heure de pointe s'applique à ce jour
     */
    public boolean sAppliqueAuJour(LocalDate date) {
        if (date == null) {
            return false;
        }
        if (jourSemaine == TOUS_LES_JOURS) {
            return true;
        }
        int jourDeLaDate = date.getDayOfWeek().getValue();
        return jourSemaine == jourDeLaDate;
    }
    
    /**
     * Vérifie si cette heure de pointe s'applique à une date au format String
     * @param dateStr La date au format dd/MM/yyyy
     * @return true si l'heure de pointe s'applique à ce jour
     */
    public boolean sAppliqueAuJour(String dateStr) {
        if (dateStr == null || dateStr.isEmpty()) {
            return false;
        }
        try {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
            LocalDate date = LocalDate.parse(dateStr, formatter);
            return sAppliqueAuJour(date);
        } catch (Exception e) {
            return false;
        }
    }
    /**
     * Récupère l'heure de début en LocalTime
     */
    public LocalTime getHeureDebutLocalTime() {
        if (heureDebut == null || heureDebut.isEmpty()) {
            return null;
        }
        return LocalTime.parse(heureDebut, TIME_FORMATTER);
    }

    /**
     * Récupère l'heure de fin en LocalTime
     */
    public LocalTime getHeureFinLocalTime() {
        if (heureFin == null || heureFin.isEmpty()) {
            return null;
        }
        return LocalTime.parse(heureFin, TIME_FORMATTER);
    }

    /**
     * Vérifie si une heure donnée est dans la période de l'heure de pointe
     * @param heure L'heure à vérifier
     * @return true si l'heure est dans la période de pointe
     */
    public boolean estDansHeurePointe(LocalTime heure) {
        if (heure == null || heureDebut == null || heureFin == null) {
            return false;
        }
        LocalTime debut = getHeureDebutLocalTime();
        LocalTime fin = getHeureFinLocalTime();
        
        // Heure >= debut ET heure < fin
        return (heure.equals(debut) || heure.isAfter(debut)) && heure.isBefore(fin);
    }
    
    /**
     * Vérifie si une heure donnée est dans la période de l'heure de pointe pour une date donnée
     * @param heure L'heure à vérifier
     * @param date La date à vérifier (pour le jour de la semaine)
     * @return true si l'heure est dans la période de pointe et le jour correspond
     */
    public boolean estDansHeurePointe(LocalTime heure, LocalDate date) {
        if (!sAppliqueAuJour(date)) {
            return false;
        }
        return estDansHeurePointe(heure);
    }

    /**
     * Vérifie si une période chevauche l'heure de pointe
     * @param heureDebutPeriode Heure de début de la période à vérifier
     * @param heureFinPeriode Heure de fin de la période à vérifier
     * @return true si la période chevauche l'heure de pointe
     */
    public boolean chevaucheHeurePointe(LocalTime heureDebutPeriode, LocalTime heureFinPeriode) {
        if (heureDebutPeriode == null || heureFinPeriode == null) {
            return false;
        }
        LocalTime hpDebut = getHeureDebutLocalTime();
        LocalTime hpFin = getHeureFinLocalTime();
        
        if (hpDebut == null || hpFin == null) {
            return false;
        }
        
        // La période chevauche si elle commence avant la fin de l'heure de pointe
        // ET se termine après le début de l'heure de pointe
        return heureDebutPeriode.isBefore(hpFin) && heureFinPeriode.isAfter(hpDebut);
    }
    
    /**
     * Vérifie si une période chevauche l'heure de pointe pour une date donnée
     * @param heureDebutPeriode Heure de début de la période à vérifier
     * @param heureFinPeriode Heure de fin de la période à vérifier
     * @param date La date à vérifier (pour le jour de la semaine)
     * @return true si la période chevauche l'heure de pointe et le jour correspond
     */
    public boolean chevaucheHeurePointe(LocalTime heureDebutPeriode, LocalTime heureFinPeriode, LocalDate date) {
        if (!sAppliqueAuJour(date)) {
            return false;
        }
        return chevaucheHeurePointe(heureDebutPeriode, heureFinPeriode);
    }

    /**
     * Calcule la durée de chevauchement entre une période et l'heure de pointe
     * @param heureDebutPeriode Heure de début de la période
     * @param heureFinPeriode Heure de fin de la période
     * @return Durée en secondes du chevauchement, 0 si pas de chevauchement
     */
    public long calculerDureeChevauchement(LocalTime heureDebutPeriode, LocalTime heureFinPeriode) {
        if (!chevaucheHeurePointe(heureDebutPeriode, heureFinPeriode)) {
            return 0;
        }
        
        LocalTime hpDebut = getHeureDebutLocalTime();
        LocalTime hpFin = getHeureFinLocalTime();
        
        // Calculer les bornes du chevauchement
        LocalTime debutChevauchement = heureDebutPeriode.isAfter(hpDebut) ? heureDebutPeriode : hpDebut;
        LocalTime finChevauchement = heureFinPeriode.isBefore(hpFin) ? heureFinPeriode : hpFin;
        
        return java.time.Duration.between(debutChevauchement, finChevauchement).getSeconds();
    }
    
    /**
     * Calcule la durée de chevauchement pour une date donnée
     * @param heureDebutPeriode Heure de début de la période
     * @param heureFinPeriode Heure de fin de la période
     * @param date La date à vérifier (pour le jour de la semaine)
     * @return Durée en secondes du chevauchement, 0 si pas de chevauchement ou jour non applicable
     */
    public long calculerDureeChevauchement(LocalTime heureDebutPeriode, LocalTime heureFinPeriode, LocalDate date) {
        if (!sAppliqueAuJour(date)) {
            return 0;
        }
        return calculerDureeChevauchement(heureDebutPeriode, heureFinPeriode);
    }

    /**
     * Récupère toutes les heures de pointe actives
     * @param c Connection à la base de données
     * @return Tableau des heures de pointe actives
     */
    public static HeurePointe[] getAllHeuresPointeActives(Connection c) throws Exception {
        boolean estOuvert = false;
        try {
            if (c == null) {
                estOuvert = true;
                c = new UtilDB().GetConn();
            }
            HeurePointe hp = new HeurePointe();
            hp.setEtat(11); // Etat validé/actif
            HeurePointe[] heuresPointe = (HeurePointe[]) CGenUtil.rechercher(hp, null, null, c, "");
            return heuresPointe != null ? heuresPointe : new HeurePointe[0];
        } finally {
            if (c != null && estOuvert) {
                c.close();
            }
        }
    }

    /**
     * Récupère les heures de pointe actives pour un support donné
     * @param idSupport ID du support (peut être null pour chercher les heures de pointe générales)
     * @param c Connection à la base de données
     * @return Tableau des heures de pointe actives pour ce support
     */
    public static HeurePointe[] getHeuresPointeBySupport(String idSupport, Connection c) throws Exception {
        boolean estOuvert = false;
        try {
            if (c == null) {
                estOuvert = true;
                c = new UtilDB().GetConn();
            }
            HeurePointe hp = new HeurePointe();
            hp.setEtat(11);
            String condition = "";
            if (idSupport != null && !idSupport.isEmpty()) {
                condition = " AND (IDSUPPORT = '" + idSupport + "' OR IDSUPPORT IS NULL)";
            }
            HeurePointe[] heuresPointe = (HeurePointe[]) CGenUtil.rechercher(hp, null, null, c, condition);
            return heuresPointe != null ? heuresPointe : new HeurePointe[0];
        } finally {
            if (c != null && estOuvert) {
                c.close();
            }
        }
    }
    
    /**
     * Récupère les heures de pointe actives pour un support et un jour de la semaine donnés
     * @param idSupport ID du support (peut être null pour chercher les heures de pointe générales)
     * @param jourSemaine Jour de la semaine (0=Tous, 1=Lundi, ..., 7=Dimanche)
     * @param c Connection à la base de données
     * @return Tableau des heures de pointe actives pour ce support et ce jour
     */
    public static HeurePointe[] getHeuresPointeByJour(String idSupport, int jourSemaine, Connection c) throws Exception {
        boolean estOuvert = false;
        try {
            if (c == null) {
                estOuvert = true;
                c = new UtilDB().GetConn();
            }
            HeurePointe hp = new HeurePointe();
            hp.setEtat(11);
            String condition = " AND (JOURSEMAINE = 0 OR JOURSEMAINE = " + jourSemaine + ")";
            if (idSupport != null && !idSupport.isEmpty()) {
                condition += " AND (IDSUPPORT = '" + idSupport + "' OR IDSUPPORT IS NULL)";
            }
            HeurePointe[] heuresPointe = (HeurePointe[]) CGenUtil.rechercher(hp, null, null, c, condition);
            return heuresPointe != null ? heuresPointe : new HeurePointe[0];
        } finally {
            if (c != null && estOuvert) {
                c.close();
            }
        }
    }
    
    /**
     * Récupère les heures de pointe actives pour un support et une date donnés
     * @param idSupport ID du support (peut être null)
     * @param date La date pour déterminer le jour de la semaine
     * @param c Connection à la base de données
     * @return Tableau des heures de pointe actives
     */
    public static HeurePointe[] getHeuresPointeByDate(String idSupport, LocalDate date, Connection c) throws Exception {
        if (date == null) {
            return getHeuresPointeBySupport(idSupport, c);
        }
        int jourSemaine = date.getDayOfWeek().getValue();
        return getHeuresPointeByJour(idSupport, jourSemaine, c);
    }

    @Override
    public String[] getMotCles() {
        String[] motCles = {"id", "heureDebut", "heureFin", "pourcentageMajoration", "designation", "etat", "idSupport", "jourSemaine"};
        return motCles;
    }

    @Override
    public String[] getValMotCles() {
        String[] motCles = {"id", "heureDebut", "heureFin", "pourcentageMajoration", "designation", "etat", "idSupport", "jourSemaine"};
        return motCles;
    }
}
