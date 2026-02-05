<%--
  Document   : heuredepointe-fiche.jsp
  Description: Fiche détaillée d'une heure de pointe
--%>
<%@page import="utilitaire.Utilitaire"%>
<%@page import="bean.CGenUtil"%>
<%@page import="heuredepointe.HeureDePointeCpl"%>
<%
    String lien = (String) session.getValue("lien");
    user.UserEJB u = (user.UserEJB) session.getValue("u");
    
    String id = request.getParameter("id");
    HeureDePointeCpl objet = new HeureDePointeCpl();
    objet.setId(id);
    objet = (HeureDePointeCpl) CGenUtil.rechercher(objet, null, null, null, "")[0];
%>

<style>
    .info-label {
        font-weight: bold;
        color: #666;
    }
    .info-value {
        font-size: 16px;
    }
    .majoration-highlight {
        background-color: #f39c12;
        color: white;
        padding: 5px 15px;
        border-radius: 4px;
        font-size: 18px;
        font-weight: bold;
    }
</style>

<div class="content-wrapper">
    <section class="content-header">
        <h1><i class="fa fa-clock-o"></i>&nbsp;&nbsp;&nbsp; Heure de Pointe - Détails</h1>
    </section>
    
    <section class="content">
        <div class="row">
            <div class="col-md-8 col-md-offset-2">
                <div class="box box-primary">
                    <div class="box-header with-border">
                        <h3 class="box-title">Détails de l'heure de pointe</h3>
                        <div class="box-tools">
                            <a href="<%=lien%>?but=heuredepointe/heuredepointe-saisie.jsp&id=<%=objet.getId()%>" class="btn btn-warning">
                                <i class="fa fa-edit"></i> Modifier
                            </a>
                        </div>
                    </div>
                    <div class="box-body">
                        <div class="row">
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label class="info-label">ID</label>
                                    <p class="info-value"><%=objet.getId()%></p>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label class="info-label">Jour de la semaine</label>
                                    <p class="info-value"><strong><%=objet.getJourLibelle()%></strong></p>
                                </div>
                            </div>
                        </div>
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label class="info-label">Heure de début</label>
                                    <p class="info-value"><%=objet.getHeureDebut()%></p>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label class="info-label">Heure de fin</label>
                                    <p class="info-value"><%=objet.getHeureFin()%></p>
                                </div>
                            </div>
                        </div>
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label class="info-label">Pourcentage de majoration</label>
                                    <p><span class="majoration-highlight">+<%=objet.getPourcentageMajoration()%>%</span></p>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label class="info-label">Support concerné</label>
                                    <p class="info-value"><%=objet.getSupportLibelle() != null ? objet.getSupportLibelle() : "Tous les supports"%></p>
                                </div>
                            </div>
                        </div>
                        
                        <div class="row">
                            <div class="col-md-12">
                                <div class="form-group">
                                    <label class="info-label">Libellé / Description</label>
                                    <p class="info-value"><%=objet.getLibelle() != null && !objet.getLibelle().isEmpty() ? objet.getLibelle() : "-"%></p>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="box-footer">
                        <a href="<%=lien%>?but=heuredepointe/heuredepointe-liste.jsp" class="btn btn-default">
                            <i class="fa fa-arrow-left"></i> Retour à la liste
                        </a>
                    </div>
                </div>
                
                <!-- Exemple de calcul -->
                <div class="box box-info">
                    <div class="box-header with-border">
                        <h3 class="box-title"><i class="fa fa-calculator"></i> Exemple de calcul</h3>
                    </div>
                    <div class="box-body">
                        <p>Pour une publicité de <strong>10 000 Ar</strong> diffusée le <strong><%=objet.getJourLibelle()%></strong> :</p>
                        <ul>
                            <li>Diffusion entièrement dans la plage <%=objet.getHeureDebut()%> - <%=objet.getHeureFin()%> : <strong><%=String.format("%.0f", 10000 * (1 + objet.getPourcentageMajoration()/100))%> Ar</strong></li>
                            <li>Diffusion partiellement dans la plage (ex: 50% du temps) : <strong><%=String.format("%.0f", 10000 * (1 + objet.getPourcentageMajoration()/200))%> Ar</strong></li>
                            <li>Diffusion hors de la plage : <strong>10 000 Ar</strong> (pas de majoration)</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </section>
</div>
