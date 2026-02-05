package heuredepointe;

import bean.ClassMAPTable;

/**
 * Classe complémentaire pour HeureDePointe avec les libellés des jointures
 */
public class HeureDePointeCpl extends ClassMAPTable {
    private String id;
    private int jour;
    private String heureDebut;
    private String heureFin;
    private double pourcentageMajoration;
    private String idSupport;
    private String libelle;
    private String jourLibelle;      // Libellé du jour (Lundi, Mardi, etc.)
    private String supportLibelle;   // Libellé du support

    public HeureDePointeCpl() throws Exception {
        setNomTable("HEUREDEPOINTE_CPL");
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
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

    public void setJour(int jour) {
        this.jour = jour;
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

    public String getJourLibelle() {
        return jourLibelle;
    }

    public void setJourLibelle(String jourLibelle) {
        this.jourLibelle = jourLibelle;
    }

    public String getSupportLibelle() {
        return supportLibelle;
    }

    public void setSupportLibelle(String supportLibelle) {
        this.supportLibelle = supportLibelle;
    }
}
