<%--
    Document   : heurepointe-fiche.jsp
    Created on : 05 f&eacute;vrier 2026
    Author     : Copilot
    Description: Fiche d'une heure de pointe de majoration
--%>

<%@page import="heurepointe.HeurePointeCpl"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@ page import="user.*" %>
<%@ page import="bean.*" %>
<%@ page import="utilitaire.*" %>
<%@ page import="affichage.*" %>

<%
    try {
        UserEJB u = (user.UserEJB) session.getValue("u");
        
        HeurePointeCpl objet = new HeurePointeCpl();
        objet.setNomTable("HEUREPOINTE_CPL");
        PageConsulte pc = new PageConsulte(objet, request, u);
        pc.setTitre("Fiche Heure de Pointe");
        pc.getBase();
        String id = pc.getBase().getTuppleID();
        
        // Configuration des libellés
        pc.getChampByName("id").setLibelle("Id");
        pc.getChampByName("designation").setLibelle("D&eacute;signation");
        pc.getChampByName("heureDebut").setLibelle("Heure de d&eacute;but");
        pc.getChampByName("heureFin").setLibelle("Heure de fin");
        pc.getChampByName("pourcentageMajoration").setLibelle("Majoration (%)");
        pc.getChampByName("idSupportLib").setLibelle("Support");
        pc.getChampByName("etatLib").setLibelle("&Eacute;tat");
        
        // Cacher certains champs
        pc.getChampByName("idSupport").setVisible(false);
        pc.getChampByName("etat").setVisible(false);
        
        String lien = (String) session.getValue("lien");
        String pageModif = "heurepointe/heurepointe-modif.jsp";
        String classe = "heurepointe.HeurePointe";
%>

<div class="content-wrapper">
    <section class="content-header">
        <h1><i class="fa fa-clock-o"></i>&nbsp;<%=pc.getTitre()%></h1>
        <ol class="breadcrumb">
            <li><a href="<%=lien%>?but=heurepointe/heurepointe-liste.jsp"><i class="fa fa-list"></i> Liste des heures de pointe</a></li>
            <li class="active">Fiche</li>
        </ol>
    </section>
    
    <section class="content">
        <div class="row">
            <div class="col-md-3"></div>
            <div class="col-md-6">
                <div class="box box-primary">
                    <div class="box-header with-border">
                        <h3 class="box-title">Informations</h3>
                    </div>
                    <div class="box-body">
                        <%
                            out.println(pc.getHtml());
                        %>
                    </div>
                    <div class="box-footer">
                        <a class="btn btn-default" href="<%=lien%>?but=heurepointe/heurepointe-liste.jsp">
                            <i class="fa fa-arrow-left"></i> Retour &agrave; la liste
                        </a>
                        <a class="btn btn-warning pull-right" href="<%=lien%>?but=<%=pageModif%>&id=<%=id%>" style="margin-right: 10px">
                            <i class="fa fa-edit"></i> Modifier
                        </a>
                        <a class="btn btn-danger pull-right" href="<%=lien%>?but=apresTarif.jsp&id=<%=id%>&acte=delete&bute=heurepointe/heurepointe-liste.jsp&classe=<%=classe%>" style="margin-right: 10px">
                            <i class="fa fa-trash"></i> Supprimer
                        </a>
                        <a class="btn btn-success pull-right" href="<%=lien%>?but=apresTarif.jsp&id=<%=id%>&acte=valider&bute=heurepointe/heurepointe-fiche.jsp&classe=<%=classe%>" style="margin-right: 10px">
                            <i class="fa fa-check"></i> Valider
                        </a>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="row">
            <div class="col-md-3"></div>
            <div class="col-md-6">
                <div class="box box-info">
                    <div class="box-header with-border">
                        <h3 class="box-title"><i class="fa fa-info-circle"></i> Explication</h3>
                    </div>
                    <div class="box-body">
                        <p>
                            Cette heure de pointe applique une majoration de 
                            <strong><%=((HeurePointeCpl)pc.getBase()).getPourcentageMajoration()%>%</strong> 
                            sur les prix des diffusions qui se déroulent entre 
                            <strong><%=((HeurePointeCpl)pc.getBase()).getHeureDebut()%></strong> et 
                            <strong><%=((HeurePointeCpl)pc.getBase()).getHeureFin()%></strong>.
                        </p>
                        <% 
                            String supportLib = ((HeurePointeCpl)pc.getBase()).getIdSupportLib();
                            if (supportLib != null && !supportLib.isEmpty()) { 
                        %>
                            <p>Cette heure de pointe s'applique uniquement au support <strong><%=supportLib%></strong>.</p>
                        <% } else { %>
                            <p>Cette heure de pointe s'applique &agrave; <strong>tous les supports</strong>.</p>
                        <% } %>
                        
                        <hr>
                        <p><strong>Exemple de calcul :</strong></p>
                        <p>Pour une diffusion de 5 minutes (300 secondes) commençant à 8h58 avec un prix de base de 10 000 Ar :</p>
                        <ul>
                            <li>Partie hors heure de pointe (8h58 - 9h00 = 2 min) : 10 000 × (120/300) = 4 000 Ar</li>
                            <li>Partie en heure de pointe (9h00 - 9h03 = 3 min) : 10 000 × (180/300) × 1.<%=String.format("%.0f", ((HeurePointeCpl)pc.getBase()).getPourcentageMajoration())%> = <%= String.format("%.0f", 10000 * (180.0/300.0) * (1 + ((HeurePointeCpl)pc.getBase()).getPourcentageMajoration()/100)) %> Ar</li>
                            <li><strong>Total : <%= String.format("%.0f", 10000 * (120.0/300.0) + 10000 * (180.0/300.0) * (1 + ((HeurePointeCpl)pc.getBase()).getPourcentageMajoration()/100)) %> Ar</strong></li>
                        </ul>
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
<div class="content-wrapper">
    <section class="content">
        <div class="alert alert-danger">
            <i class="fa fa-exclamation-triangle"></i> Erreur: <%=e.getMessage()%>
        </div>
        <a href="javascript:history.back()" class="btn btn-default">
            <i class="fa fa-arrow-left"></i> Retour
        </a>
    </section>
</div>
<% } %>
