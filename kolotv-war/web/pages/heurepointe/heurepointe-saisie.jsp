<%--
    Document   : heurepointe-saisie.jsp
    Created on : 05 f&eacute;vrier 2026
    Author     : Copilot
    Description: Saisie d'une nouvelle heure de pointe de majoration
--%>
<%@page import="utilitaire.Utilitaire"%>
<%@page import="heurepointe.HeurePointe"%>
<%@page import="support.Support"%>
<%@page import="affichage.PageInsert"%>
<%@page import="user.UserEJB"%>
<%@page import="affichage.Liste"%>
<%@page import="affichage.Champ"%>
<%@page import="affichage.Select"%>

<%
    try {
        UserEJB u = (user.UserEJB) session.getValue("u");
        String mapping = "heurepointe.HeurePointe",
               nomtable = "HEUREPOINTE",
               apres = "heurepointe/heurepointe-fiche.jsp",
               titre = "Nouvelle Heure de Pointe";

        HeurePointe objet = new HeurePointe();
        objet.setNomTable("HEUREPOINTE");
        PageInsert pi = new PageInsert(objet, request, u);
        pi.setLien((String) session.getValue("lien"));
        
        // Configuration des champs
        pi.getFormu().getChamp("designation").setLibelle("D&eacute;signation");
        pi.getFormu().getChamp("heureDebut").setLibelle("Heure de d&eacute;but");
        pi.getFormu().getChamp("heureDebut").setAutre("type='time' required");
        pi.getFormu().getChamp("heureFin").setLibelle("Heure de fin");
        pi.getFormu().getChamp("heureFin").setAutre("type='time' required");
        pi.getFormu().getChamp("pourcentageMajoration").setLibelle("Pourcentage de majoration (%)");
        pi.getFormu().getChamp("pourcentageMajoration").setAutre("type='number' step='0.01' min='0' max='100' required");
        
        // Champ Jour de la semaine (liste déroulante)
        String[][] joursOptions = {
            {"0", "Tous les jours"},
            {"1", "Lundi"},
            {"2", "Mardi"},
            {"3", "Mercredi"},
            {"4", "Jeudi"},
            {"5", "Vendredi"},
            {"6", "Samedi"},
            {"7", "Dimanche"}
        };
        affichage.Champ[] listeChamps = new affichage.Champ[2];
        listeChamps[0] = new Liste("idSupport", new Support(), "val", "id");
        listeChamps[1] = new Select("jourSemaine", joursOptions);
        pi.getFormu().changerEnChamp(listeChamps);
        pi.getFormu().getChamp("idSupport").setLibelle("Support (optionnel)");
        pi.getFormu().getChamp("jourSemaine").setLibelle("Jour de la semaine");
        
        // Cacher le champ ID et ETAT
        pi.getFormu().getChamp("id").setVisible(false);
        pi.getFormu().getChamp("etat").setVisible(false);

        pi.preparerDataFormu();
%>
<div class="content-wrapper">
    <section class="content-header">
        <h1><i class="fa fa-clock-o"></i>&nbsp;<%=titre%></h1>
        <ol class="breadcrumb">
            <li><a href="<%=pi.getLien()%>?but=heurepointe/heurepointe-liste.jsp"><i class="fa fa-list"></i> Liste des heures de pointe</a></li>
            <li class="active">Nouvelle</li>
        </ol>
    </section>
    
    <section class="content">
        <div class="box box-primary">
            <div class="box-header with-border">
                <h3 class="box-title">Informations de l'heure de pointe</h3>
            </div>
            <div class="box-body">
                <form action="<%=pi.getLien()%>?but=apresTarif.jsp" method="post" name="<%=nomtable%>" id="<%=nomtable%>" data-parsley-validate>
                    <%
                        pi.getFormu().makeHtmlInsertTabIndex();
                        out.println(pi.getFormu().getHtmlInsert());
                    %>
                    <input name="acte" type="hidden" id="nature" value="insert">
                    <input name="bute" type="hidden" id="bute" value="<%=apres%>">
                    <input name="classe" type="hidden" id="classe" value="<%=mapping%>">
                    <input name="nomtable" type="hidden" id="nomtable" value="<%=nomtable%>">
                </form>
            </div>
            <div class="box-footer">
                <a href="<%=pi.getLien()%>?but=heurepointe/heurepointe-liste.jsp" class="btn btn-default">
                    <i class="fa fa-arrow-left"></i> Retour
                </a>
            </div>
        </div>
        
        <div class="box box-info">
            <div class="box-header with-border">
                <h3 class="box-title"><i class="fa fa-info-circle"></i> Aide</h3>
            </div>
            <div class="box-body">
                <p><strong>Heure de pointe :</strong> Période durant laquelle un pourcentage de majoration est appliqué sur les prix de diffusion.</p>
                <p><strong>Jour de la semaine :</strong> Choisissez un jour spécifique ou "Tous les jours" pour appliquer la majoration quotidiennement.</p>
                <p><strong>Exemple :</strong> Si vous définissez une heure de pointe de 9h à 11h avec 10% de majoration uniquement le Lundi :</p>
                <ul>
                    <li>Une diffusion le Lundi à 9h30 sera majorée de 10%</li>
                    <li>La même diffusion le Mardi ne sera pas majorée</li>
                </ul>
                <p><strong>Support :</strong> Si aucun support n'est sélectionné, l'heure de pointe s'applique à tous les supports.</p>
            </div>
        </div>
    </section>
</div>

<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script language="JavaScript">
    alert('Erreur: <%=e.getMessage()%>');
    history.back();
</script>
<% } %>
