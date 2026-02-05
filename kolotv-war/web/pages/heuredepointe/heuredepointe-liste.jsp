<%--
  Document   : heuredepointe-liste.jsp
  Description: Liste des heures de pointe
--%>
<%@page import="utilitaire.Utilitaire"%>
<%@page import="bean.CGenUtil"%>
<%@page import="heuredepointe.HeureDePointeCpl"%>
<%@page import="affichage.ParamRecherche"%>
<%
    String lien = (String) session.getValue("lien");
    user.UserEJB u = (user.UserEJB) session.getValue("u");
    
    HeureDePointeCpl t = new HeureDePointeCpl();
    t.setNomTable("HEUREDEPOINTE_CPL");
    
    ParamRecherche pr = new ParamRecherche();
    pr.setLien(lien);
    pr.setApres("heuredepointe/heuredepointe-liste.jsp");
    pr.setNbLigne(20);
    
    String[] col = {"ID", "Jour", "Heure Début", "Heure Fin", "Majoration (%)", "Support", "Libellé"};
    String[] champs = {"id", "jourLibelle", "heureDebut", "heureFin", "pourcentageMajoration", "supportLibelle", "libelle"};
    String[] lienTableau = {pr.getLien() + "?but=heuredepointe/heuredepointe-fiche.jsp"};
    String[] champslien = {"id"};
%>

<style>
    .table-heuredepointe th {
        background-color: #3c8dbc;
        color: white;
    }
    .majoration-badge {
        background-color: #f39c12;
        color: white;
        padding: 2px 8px;
        border-radius: 4px;
        font-weight: bold;
    }
</style>

<div class="content-wrapper">
    <section class="content-header">
        <h1><i class="fa fa-clock-o"></i>&nbsp;&nbsp;&nbsp; Heures de Pointe</h1>
    </section>
    
    <section class="content">
        <div class="row">
            <div class="col-xs-12">
                <div class="box box-primary">
                    <div class="box-header with-border">
                        <h3 class="box-title">Liste des heures de pointe avec majoration</h3>
                        <div class="box-tools">
                            <a href="<%=lien%>?but=heuredepointe/heuredepointe-saisie.jsp" class="btn btn-success">
                                <i class="fa fa-plus"></i> Nouvelle heure de pointe
                            </a>
                        </div>
                    </div>
                    <div class="box-body">
                        <%
                            HeureDePointeCpl[] liste = (HeureDePointeCpl[]) CGenUtil.rechercher(t, null, null, null, "ORDER BY jour, heureDebut");
                        %>
                        <table class="table table-bordered table-striped table-heuredepointe">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Jour</th>
                                    <th>Heure Début</th>
                                    <th>Heure Fin</th>
                                    <th>Majoration</th>
                                    <th>Support</th>
                                    <th>Libellé</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% for (int i = 0; i < liste.length; i++) { 
                                    HeureDePointeCpl hdp = liste[i];
                                %>
                                <tr>
                                    <td><%=i + 1%></td>
                                    <td><strong><%=hdp.getJourLibelle()%></strong></td>
                                    <td><%=hdp.getHeureDebut()%></td>
                                    <td><%=hdp.getHeureFin()%></td>
                                    <td><span class="majoration-badge">+<%=hdp.getPourcentageMajoration()%>%</span></td>
                                    <td><%=hdp.getSupportLibelle() != null ? hdp.getSupportLibelle() : "Tous"%></td>
                                    <td><%=hdp.getLibelle() != null ? hdp.getLibelle() : ""%></td>
                                    <td>
                                        <a href="<%=lien%>?but=heuredepointe/heuredepointe-fiche.jsp&id=<%=hdp.getId()%>" class="btn btn-info btn-xs">
                                            <i class="fa fa-eye"></i>
                                        </a>
                                        <a href="<%=lien%>?but=heuredepointe/heuredepointe-saisie.jsp&id=<%=hdp.getId()%>" class="btn btn-warning btn-xs">
                                            <i class="fa fa-edit"></i>
                                        </a>
                                    </td>
                                </tr>
                                <% } %>
                                <% if (liste.length == 0) { %>
                                <tr>
                                    <td colspan="8" class="text-center">Aucune heure de pointe configurée</td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
                
                <!-- Légende -->
                <div class="box box-info">
                    <div class="box-header with-border">
                        <h3 class="box-title"><i class="fa fa-info-circle"></i> Information</h3>
                    </div>
                    <div class="box-body">
                        <p>Les heures de pointe permettent d'appliquer une majoration sur le prix des diffusions pendant les périodes à forte audience.</p>
                        <p>Exemple : Si une publicité de 10 000 Ar est diffusée pendant une heure de pointe avec +10% de majoration, son prix devient 11 000 Ar.</p>
                        <p>Le calcul est proportionnel : si la diffusion chevauche partiellement une heure de pointe, seule la partie concernée est majorée.</p>
                    </div>
                </div>
            </div>
        </div>
    </section>
</div>
