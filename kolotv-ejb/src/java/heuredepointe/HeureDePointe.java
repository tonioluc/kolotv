package heuredepointe;

import bean.ClassMAPTable;
import bean.CGenUtil;
import utilitaire.UtilDB;
import utils.CalendarUtil;

import java.sql.Connection;
import java.sql.Date;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Classe représentant une heure de pointe avec majoration de prix
 * Les heures de pointe sont des plages horaires pendant lesquelles
 * le prix des diffusions est majoré d'un certain pourcentage
 */
public class HeureDePointe extends ClassMAPTable {
    private String id;
    private int jour;                    // 1=Lundi, 2=Mardi, ..., 7=Dimanche
    private String heureDebut;           // Format HH:mm:ss
    private String heureFin;             // Format HH:mm:ss
    private double pourcentageMajoration; // Pourcentage de majoration (ex: 10 pour 10%)
    private String idSupport;            // Support concerné (null = tous)
    private String libelle;              // Description

    public HeureDePointe() throws Exception {
        setNomTable("HEUREDEPOINTE");
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    public void construirePK(Connection c) throws Exception {
        this.preparePk("HDP", "GETSEQHEUREDEPOINTE");
        this.setId(makePK(c));
    }

    // Getters et Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public int getJour() {
        return jour;
    }

    public void setJour(int jour) throws Exception {
        if (jour < 1 || jour > 7) {
            throw new Exception("Le jour doit être entre 1 (Lundi) et 7 (Dimanche)");
        }
        this.jour = jour;
    }

    public String getHeureDebut() {
        return heureDebut;
    }

    public void setHeureDebut(String heureDebut) throws Exception {
        if (!CalendarUtil.isValidTime(heureDebut)) {
            throw new Exception("L'heure de début doit être au format HH:mm:ss");
        }
        this.heureDebut = heureDebut;
    }

    public String getHeureFin() {
        return heureFin;
    }

    public void setHeureFin(String heureFin) throws Exception {
        if (!CalendarUtil.isValidTime(heureFin)) {
            throw new Exception("L'heure de fin doit être au format HH:mm:ss");
        }
        this.heureFin = heureFin;
    }

    public double getPourcentageMajoration() {
        return pourcentageMajoration;
    }

    public void setPourcentageMajoration(double pourcentageMajoration) throws Exception {
        if (pourcentageMajoration < 0) {
            throw new Exception("Le pourcentage de majoration ne peut pas être négatif");
        }
        this.pourcentageMajoration = pourcentageMajoration;
    }

    public String getIdSupport() {
        return idSupport;
    }

    public void setIdSupport(String idSupport) {
        this.idSupport = idSupport;
    }

    public String getLibelle() {
        return libelle;
    }

    public void setLibelle(String libelle) {
        this.libelle = libelle;
    }

    /**
     * Retourne le libellé du jour de la semaine
     */
    public String getJourLibelle() {
        String[] jours = {"", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"};
        if (jour >= 1 && jour <= 7) {
            return jours[jour];
        }
        return "";
    }

    /**
     * Récupère toutes les heures de pointe pour un jour et un support donnés
     * @param jour Jour de la semaine (1-7)
     * @param idSupport ID du support (peut être null pour tous les supports)
     * @param c Connection à la base de données
     * @return Liste des heures de pointe applicables
     */
    public static HeureDePointe[] getHeuresDePointe(int jour, String idSupport, Connection c) throws Exception {
        boolean estOuvert = false;
        try {
            if (c == null) {
                c = new UtilDB().GetConn();
                estOuvert = true;
            }

            List<HeureDePointe> result = new ArrayList<>();
            
            // Rechercher les heures de pointe pour ce jour
            HeureDePointe search = new HeureDePointe();
            search.setJour(jour);
            HeureDePointe[] heures = (HeureDePointe[]) CGenUtil.rechercher(search, null, null, c, "");
            
            for (HeureDePointe h : heures) {
                // Inclure si pas de support spécifié ou si le support correspond
                if (h.getIdSupport() == null || h.getIdSupport().isEmpty() 
                    || (idSupport != null && h.getIdSupport().equals(idSupport))) {
                    result.add(h);
                }
            }
            
            return result.toArray(new HeureDePointe[0]);
        } finally {
            if (c != null && estOuvert) {
                c.close();
            }
        }
    }

    /**
     * Récupère toutes les heures de pointe pour une date et un support donnés
     * @param date Date de diffusion
     * @param idSupport ID du support
     * @param c Connection
     * @return Liste des heures de pointe applicables
     */
    public static HeureDePointe[] getHeuresDePointeParDate(Date date, String idSupport, Connection c) throws Exception {
        LocalDate localDate = date.toLocalDate();
        int jour = CalendarUtil.getDayOfWeekNumber(localDate);
        return getHeuresDePointe(jour, idSupport, c);
    }

    /**
     * Calcule le coefficient de majoration pour une plage horaire donnée
     * Retourne 1.0 si pas de majoration, 1.10 pour 10% de majoration, etc.
     * @param heureDebut Heure de début
     * @param heureFin Heure de fin
     * @return Coefficient de majoration
     */
    public double getCoefficient(LocalTime heureDebut, LocalTime heureFin) {
        LocalTime hdpDebut = LocalTime.parse(this.heureDebut);
        LocalTime hdpFin = LocalTime.parse(this.heureFin);
        
        // Vérifier s'il y a chevauchement
        if (heureFin.isBefore(hdpDebut) || heureFin.equals(hdpDebut) || 
            heureDebut.isAfter(hdpFin) || heureDebut.equals(hdpFin)) {
            return 1.0; // Pas de chevauchement, pas de majoration
        }
        
        return 1.0 + (pourcentageMajoration / 100.0);
    }

    /**
     * Vérifie si une heure est dans cette plage d'heure de pointe
     */
    public boolean contientHeure(LocalTime heure) {
        LocalTime hdpDebut = LocalTime.parse(this.heureDebut);
        LocalTime hdpFin = LocalTime.parse(this.heureFin);
        
        return (heure.equals(hdpDebut) || heure.isAfter(hdpDebut)) && heure.isBefore(hdpFin);
    }

    /**
     * Calcule la durée de chevauchement avec cette heure de pointe
     * @param heureDebut Heure de début de la diffusion
     * @param heureFin Heure de fin de la diffusion
     * @return Durée de chevauchement en secondes
     */
    public long getDureeChevauchement(LocalTime heureDebut, LocalTime heureFin) {
        LocalTime hdpDebut = LocalTime.parse(this.heureDebut);
        LocalTime hdpFin = LocalTime.parse(this.heureFin);
        
        // Trouver le début effectif du chevauchement
        LocalTime debutEffectif = heureDebut.isAfter(hdpDebut) ? heureDebut : hdpDebut;
        // Trouver la fin effective du chevauchement
        LocalTime finEffective = heureFin.isBefore(hdpFin) ? heureFin : hdpFin;
        
        // Si pas de chevauchement, retourner 0
        if (debutEffectif.isAfter(finEffective) || debutEffectif.equals(finEffective)) {
            return 0;
        }
        
        return CalendarUtil.getDuration(debutEffectif, finEffective);
    }
}
