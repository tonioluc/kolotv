<%-- 
    Document   : heurepointe-modif
    Created on : 05 f&eacute;vrier 2026
    Author     : Copilot
    Description: Modification d'une heure de pointe de majoration
--%>

<%@page import="heurepointe.HeurePointe"%>
<%@page import="support.Support"%>
<%@ page import="user.*"%>
<%@ page import="bean.*"%>
<%@ page import="utilitaire.*"%>
<%@ page import="affichage.*"%>

<%
    try {
        HeurePointe t = new HeurePointe();
        
        String mapping = "heurepointe.HeurePointe",
               nomtable = "HEUREPOINTE",
               apres = "heurepointe/heurepointe-fiche.jsp",
               titre = "Modification Heure de Pointe";
        
        PageUpdate pu = new PageUpdate(t, request, (user.UserEJB) session.getValue("u"));
        pu.setLien((String) session.getValue("lien"));
        pu.setTitre("Modification de l'Heure de Pointe");
        
        // Configuration des champs
        pu.getFormu().getChamp("id").setAutre("readonly");
        pu.getFormu().getChamp("designation").setLibelle("D&eacute;signation");
        pu.getFormu().getChamp("heureDebut").setLibelle("Heure de d&eacute;but");
        pu.getFormu().getChamp("heureDebut").setAutre("type='time' required");
        pu.getFormu().getChamp("heureFin").setLibelle("Heure de fin");
        pu.getFormu().getChamp("heureFin").setAutre("type='time' required");
        pu.getFormu().getChamp("pourcentageMajoration").setLibelle("Pourcentage de majoration (%)");
        pu.getFormu().getChamp("pourcentageMajoration").setAutre("type='number' step='0.01' min='0' max='100' required");
        
        // Liste déroulante pour le support
        affichage.Champ[] liste = new affichage.Champ[1];
        liste[0] = new Liste("idSupport", new Support(), "val", "id");
        pu.getFormu().changerEnChamp(liste);
        pu.getFormu().getChamp("idSupport").setLibelle("Support (optionnel)");
        
        // Cacher le champ ETAT
        pu.getFormu().getChamp("etat").setVisible(false);
        
        String lien = (String) session.getValue("lien");
        String id = pu.getBase().getTuppleID();
        pu.preparerDataFormu();
%>
<div class="content-wrapper">
    <section class="content-header">
        <h1><i class="fa fa-clock-o"></i>&nbsp;<%=pu.getTitre()%></h1>
        <ol class="breadcrumb">
            <li><a href="<%=lien%>?but=heurepointe/heurepointe-liste.jsp"><i class="fa fa-list"></i> Liste</a></li>
            <li><a href="<%=lien%>?but=heurepointe/heurepointe-fiche.jsp&id=<%=id%>"><i class="fa fa-file-text"></i> Fiche</a></li>
            <li class="active">Modification</li>
        </ol>
    </section>
    
    <section class="content">
        <div class="row">
            <div class="col-md-3"></div>
            <div class="col-md-6">
                <div class="box box-warning">
                    <div class="box-header with-border">
                        <h3 class="box-title">Modification</h3>
                    </div>
                    <div class="box-body">
                        <form action="<%=lien%>?but=apresTarif.jsp&id=<%=request.getParameter("id")%>" method="post" data-parsley-validate>
                            <%
                                out.println(pu.getFormu().getHtmlInsert());
                            %>
                            <div class="row">
                                <div class="col-md-12">
                                    <a href="<%=lien%>?but=heurepointe/heurepointe-fiche.jsp&id=<%=id%>" class="btn btn-default">
                                        <i class="fa fa-arrow-left"></i> Annuler
                                    </a>
                                    <button class="btn btn-primary pull-right" name="Submit2" type="submit">
                                        <i class="fa fa-save"></i> Enregistrer
                                    </button>
                                </div>
                            </div>
                            <input name="acte" type="hidden" id="acte" value="update">
                            <input name="bute" type="hidden" id="bute" value="<%=apres%>">
                            <input name="classe" type="hidden" id="classe" value="<%=mapping%>">
                            <input name="rajoutLien" type="hidden" id="rajoutLien" value="id-<%=request.getParameter("id")%>">
                            <input name="nomtable" type="hidden" id="nomtable" value="<%=nomtable%>">
                        </form>
                    </div>
                </div>
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
