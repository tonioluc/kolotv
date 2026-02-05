<%-- 
    Document   : heurepointe-liste
    Created on : 05 f&eacute;vrier 2026
    Author     : Copilot
    Description: Liste des heures de pointe de majoration
--%>

<%@page import="heurepointe.HeurePointeCpl"%>
<%@page import="affichage.PageRecherche"%>

<% try{ 
    HeurePointeCpl t = new HeurePointeCpl();
    t.setNomTable("HEUREPOINTE_CPL");
    String listeCrt[] = {"id", "designation", "heureDebut", "heureFin", "pourcentageMajoration", "idSupportLib", "etatLib"};
    String listeInt[] = {};
    String libEntete[] = {"id", "designation", "heureDebut", "heureFin", "pourcentageMajoration", "idSupportLib", "etatLib"};
    PageRecherche pr = new PageRecherche(t, request, listeCrt, listeInt, 3, libEntete, libEntete.length);
    pr.setTitre("Liste des Heures de Pointe");
    pr.setUtilisateur((user.UserEJB) session.getValue("u"));
    pr.setLien((String) session.getValue("lien"));
    pr.setApres("heurepointe/heurepointe-liste.jsp");
    pr.getFormu().getChamp("id").setLibelle("Id");
    pr.getFormu().getChamp("designation").setLibelle("D&eacute;signation");
    pr.getFormu().getChamp("heureDebut").setLibelle("Heure D&eacute;but");
    pr.getFormu().getChamp("heureFin").setLibelle("Heure Fin");
    pr.getFormu().getChamp("pourcentageMajoration").setLibelle("Majoration (%)");
    pr.getFormu().getChamp("idSupportLib").setLibelle("Support");
    pr.getFormu().getChamp("etatLib").setLibelle("&Eacute;tat");
    String[] colSomme = null;
    pr.creerObjetPage(libEntete, colSomme);
    
    // Definition des liens pour le tableau
    String lienTableau[] = {pr.getLien() + "?but=heurepointe/heurepointe-fiche.jsp"};
    String colonneLien[] = {"id"};
    pr.getTableau().setLien(lienTableau);
    pr.getTableau().setColonneLien(colonneLien);
    
    String libEnteteAffiche[] = {"ID", "D&eacute;signation", "Heure D&eacute;but", "Heure Fin", "Majoration (%)", "Support", "&Eacute;tat"};
    pr.getTableau().setLibelleAffiche(libEnteteAffiche);
%>

<div class="content-wrapper">
    <section class="content-header">
        <h1><i class="fa fa-clock-o"></i>&nbsp;<%= pr.getTitre() %></h1>
    </section>
    <section class="content">
        <div class="box box-primary">
            <div class="box-header with-border">
                <h3 class="box-title">Recherche</h3>
            </div>
            <div class="box-body">
                <form action="<%=pr.getLien()%>?but=<%= pr.getApres() %>" method="post">
                    <%
                        out.println(pr.getFormu().getHtmlEnsemble());
                    %>
                </form>
            </div>
        </div>
        
        <div class="box box-info">
            <div class="box-header with-border">
                <h3 class="box-title">R&eacute;sultats</h3>
                <div class="box-tools pull-right">
                    <a href="<%=pr.getLien()%>?but=heurepointe/heurepointe-saisie.jsp" class="btn btn-success btn-sm">
                        <i class="fa fa-plus"></i> Nouvelle Heure de Pointe
                    </a>
                </div>
            </div>
            <div class="box-body">
                <%
                    out.println(pr.getTableauRecap().getHtml());
                %>
                <br>
                <%
                    out.println(pr.getTableau().getHtml());
                    out.println(pr.getBasPage());
                %>
            </div>
        </div>
    </section>
</div>
<%
    } catch(Exception e) {
        e.printStackTrace();
        out.println("<div class='alert alert-danger'>Erreur: " + e.getMessage() + "</div>");
    }
%>
