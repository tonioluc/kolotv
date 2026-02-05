<%--
  Document   : heuredepointe-saisie.jsp
  Description: Formulaire de saisie pour les heures de pointe
--%>
<%@page import="utilitaire.Utilitaire"%>
<%@page import="bean.CGenUtil"%>
<%@page import="heuredepointe.HeureDePointe"%>
<%@page import="support.Support"%>
<%
    String lien = (String) session.getValue("lien");
    user.UserEJB u = (user.UserEJB) session.getValue("u");
    
    String mapping = "heuredepointe.HeureDePointe",
           nomtable = "HeureDePointe",
           apres = "heuredepointe/heuredepointe-fiche.jsp",
           tablef = null;
           
    HeureDePointe objet = new HeureDePointe();
    objet.setNomTable("HeureDePointe");
    
    String id = request.getParameter("id");
    if (id != null && !id.isEmpty()) {
        objet.setId(id);
        objet = (HeureDePointe) CGenUtil.rechercher(objet, null, null, null, "")[0];
    }
    
    Support[] supports = (Support[]) CGenUtil.rechercher(new Support(), null, null, null, "");
%>
<style>
    .form-input {
        margin-bottom: 15px;
    }
    .labelinput {
        font-weight: bold;
        margin-bottom: 5px;
    }
</style>

<div class="content-wrapper">
    <section class="content-header">
        <h1><i class="fa fa-clock-o"></i>&nbsp;&nbsp;&nbsp; Heure de Pointe - Saisie</h1>
    </section>
    
    <section class="content">
        <div class="row">
            <div class="col-md-8 col-md-offset-2">
                <div class="box box-primary">
                    <div class="box-header with-border">
                        <h3 class="box-title"><%=id != null ? "Modification" : "Nouvelle"%> Heure de Pointe</h3>
                    </div>
                    <form action="<%=lien%>" method="POST">
                        <div class="box-body">
                            <input type="hidden" name="mapping" value="<%=mapping%>">
                            <input type="hidden" name="tablef" value="<%=tablef%>">
                            <input type="hidden" name="nomtable" value="<%=nomtable%>">
                            <input type="hidden" name="apres" value="<%=apres%>">
                            <input type="hidden" name="but" value="controleur.jsp">
                            <input type="hidden" name="action" value="insert">
                            <% if (id != null) { %>
                            <input type="hidden" name="id" value="<%=id%>">
                            <% } %>
                            
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-input">
                                        <label class="labelinput">Jour de la semaine *</label>
                                        <select class="form-control" name="jour" required>
                                            <option value="">-- Sélectionner --</option>
                                            <option value="1" <%=objet.getJour() == 1 ? "selected" : ""%>>Lundi</option>
                                            <option value="2" <%=objet.getJour() == 2 ? "selected" : ""%>>Mardi</option>
                                            <option value="3" <%=objet.getJour() == 3 ? "selected" : ""%>>Mercredi</option>
                                            <option value="4" <%=objet.getJour() == 4 ? "selected" : ""%>>Jeudi</option>
                                            <option value="5" <%=objet.getJour() == 5 ? "selected" : ""%>>Vendredi</option>
                                            <option value="6" <%=objet.getJour() == 6 ? "selected" : ""%>>Samedi</option>
                                            <option value="7" <%=objet.getJour() == 7 ? "selected" : ""%>>Dimanche</option>
                                        </select>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-input">
                                        <label class="labelinput">Pourcentage de majoration (%) *</label>
                                        <input type="number" step="0.01" class="form-control" name="pourcentageMajoration" 
                                               value="<%=objet.getPourcentageMajoration() > 0 ? objet.getPourcentageMajoration() : 10%>" required>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-input">
                                        <label class="labelinput">Heure de début *</label>
                                        <input type="time" class="form-control" name="heureDebut" 
                                               value="<%=objet.getHeureDebut() != null ? objet.getHeureDebut().substring(0, 5) : ""%>" required>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-input">
                                        <label class="labelinput">Heure de fin *</label>
                                        <input type="time" class="form-control" name="heureFin" 
                                               value="<%=objet.getHeureFin() != null ? objet.getHeureFin().substring(0, 5) : ""%>" required>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-input">
                                        <label class="labelinput">Support (optionnel)</label>
                                        <select class="form-control" name="idSupport">
                                            <option value="">Tous les supports</option>
                                            <% for (Support s : supports) { %>
                                            <option value="<%=s.getId()%>" <%=s.getId().equals(objet.getIdSupport()) ? "selected" : ""%>><%=s.getVal()%></option>
                                            <% } %>
                                        </select>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-input">
                                        <label class="labelinput">Libellé / Description</label>
                                        <input type="text" class="form-control" name="libelle" 
                                               value="<%=objet.getLibelle() != null ? objet.getLibelle() : ""%>">
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="box-footer">
                            <a href="<%=lien%>?but=heuredepointe/heuredepointe-liste.jsp" class="btn btn-default">
                                <i class="fa fa-arrow-left"></i> Retour
                            </a>
                            <button type="reset" class="btn btn-warning">
                                <i class="fa fa-refresh"></i> Réinitialiser
                            </button>
                            <button type="submit" class="btn btn-success pull-right">
                                <i class="fa fa-save"></i> Enregistrer
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </section>
</div>
