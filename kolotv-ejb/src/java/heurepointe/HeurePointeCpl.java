package heurepointe;

import bean.CGenUtil;
import java.sql.Connection;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import utilitaire.UtilDB;

/**
 * Classe avec vue complémentaire pour HeurePointe
 * Inclut les libellés des relations
 * 
 * @author Copilot
 */
public class HeurePointeCpl extends HeurePointe {
    
    private String idSupportLib;
    private String etatLib;
    private String jourSemaineLib;

    public HeurePointeCpl() {
        this.setNomTable("HEUREPOINTE_CPL");
    }

    public String getIdSupportLib() {
        return idSupportLib;
    }

    public void setIdSupportLib(String idSupportLib) {
        this.idSupportLib = idSupportLib;
    }

    public String getEtatLib() {
        return etatLib;
    }

    public void setEtatLib(String etatLib) {
        this.etatLib = etatLib;
    }

    @Override
    public String getJourSemaineLib() {
        return jourSemaineLib;
    }

    public void setJourSemaineLib(String jourSemaineLib) {
        this.jourSemaineLib = jourSemaineLib;
    }

    @Override
    public String[] getMotCles() {
        String[] motCles = {"id", "heureDebut", "heureFin", "pourcentageMajoration", "designation", "etat", "idSupport", "jourSemaine", "idSupportLib", "etatLib", "jourSemaineLib"};
        return motCles;
    }

    @Override
    public String[] getValMotCles() {
        String[] motCles = {"id", "heureDebut", "heureFin", "pourcentageMajoration", "designation", "etat", "idSupport", "jourSemaine", "idSupportLib", "etatLib", "jourSemaineLib"};
        return motCles;
    }
}
