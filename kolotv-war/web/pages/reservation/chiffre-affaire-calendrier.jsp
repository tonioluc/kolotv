<%--
  Page: Chiffre d'affaires par tranche horaire
  Description: Affiche le chiffre d'affaires par tranche horaire (00h-23h) sous forme de calendrier hebdomadaire
               Avec prise en compte des majorations d'heures de pointe
--%>
<%@ page import="affichage.*" %>
<%@page import="java.util.Map"%>
<%@page import="java.util.HashMap"%>
<%@ page import="reservation.EtatChiffreAffaire" %>
<%@ page import="reservation.ReservationDetailsAvecDiffusion" %>
<%@ page import="utils.CalendarUtil" %>
<%@ page import="utils.UrlUtils" %>
<%@ page import="java.time.LocalDate, java.time.format.DateTimeFormatter" %>
<%@ page import="utilitaire.Utilitaire" %>
<%@ page import="java.time.LocalTime" %>
<%@ page import="java.util.List" %>
<%@ page import="support.Support" %>
<%@ page import="bean.CGenUtil" %>
<%@ page import="produits.CategorieIngredient" %>
<%@ page import="heurepointe.HeurePointe" %>
<%@ page import="heurepointe.HeurePointeUtils" %>


<style>
.form-input {
  margin-bottom: 0px;
}
table td{
  max-width: 30%;
}
.calendar-grid {
  width: 100%;
  background-color: white;
  overflow: hidden;
  border-radius: 2px;
}
.calendar-cell {
  border-style: solid;
  border-width: 0.5px;
  border-color: #c8c8c8;
  padding: 15px 10px;
  text-align: center;
  cursor: pointer;
  transition: 0.3s ease;
}
.calendar-cell:hover {
  background-color: #f0f7ff;
  box-shadow: inset 0 0 5px rgba(0,54,149,0.2);
}
.calendar-cell.has-data {
  background-color: #e8f5e9;
}
.calendar-cell.has-data:hover {
  background-color: #c8e6c9;
}

.calendar-cell.has-majoration {
  background-color: #fff3e0;
  border-left: 3px solid #ff9800;
}
.calendar-cell.has-majoration:hover {
  background-color: #ffe0b2;
}

.day-btn {
  cursor: pointer;
  color: white;
  background-color: #003695db;
  padding: 10px 2px;
  text-align: center;
  font-size: 18px;
  border-style: solid;
  border-width: 0.5px;
  border-color: #c8c8c8;
  font-weight: bold;
  transition: 0.3s ease;
}
.day-btn:hover{
  color: rgba(255, 255, 255, 0.87);
  background-color: #0b3881;
}

.calendar-cell-title{
  padding: 10px 2px;
  text-align: center;
  font-size: 16px;
  background-color: rgba(231, 231, 231, 0.334);
  border-style: solid;
  border-width: 0.5px;
  border-color: #c8c8c8;
  font-weight: bold;
}

.calendar-footer{
  border-style: solid;
  border-width: 0.5px;
  border-color: #c8c8c8;
  padding: 10px;
  background-color: #fff3e0;
  font-weight: bold;
}

.calendar-total-tranche {
  border-style: solid;
  border-width: 0.5px;
  border-color: #c8c8c8;
  padding: 10px;
  background-color: #e3f2fd;
  font-weight: bold;
  text-align: center;
}

.majoration-badge {
  display: inline-block;
  background-color: #ff9800;
  color: white;
  font-size: 10px;
  padding: 2px 5px;
  border-radius: 3px;
  margin-left: 3px;
}

.total-majoration {
  background-color: #ff9800;
  color: white;
  font-size: 14px;
  font-weight: bold;
  padding: 10px 15px;
  border-radius: 8px;
  margin-left: 10px;
}

.ca-avec-majoration {
  color: #e65100;
  font-size: 12px;
  margin-top: 2px;
}

.montant-cell {
  font-size: 14px;
  font-weight: bold;
  color: #2e7d32;
}
.montant-cell.zero {
  color: #9e9e9e;
  font-weight: normal;
}
.nb-reservations {
  font-size: 11px;
  color: #757575;
  margin-top: 2px;
}

.total-semaine {
  background-color: #1565c0;
  color: white;
  font-size: 18px;
  font-weight: bold;
  padding: 15px;
}

.nav-tabs-custom {
  margin-bottom: 20px;
}
.nav-tabs-custom .nav-tabs li a {
  color: #333;
}
.nav-tabs-custom .nav-tabs li.active a {
  color: #003695;
  font-weight: bold;
}
</style>

<%
  try{
    String lien = (String) session.getValue("lien");
    user.UserEJB u= (user.UserEJB) session.getValue("u");

    /* Récuperer la date par défaut */
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    String dateEncours = request.getParameter("d");
    if (dateEncours!=null){
      dateEncours = CalendarUtil.castDateToFormat(dateEncours,DateTimeFormatter.ofPattern("yyyy-MM-dd"),formatter);
    }
    if (dateEncours == null || dateEncours.trim().isEmpty()) {
      LocalDate aujourdHui = LocalDate.now();
      dateEncours = aujourdHui.format(formatter);
    }

    String debutEtFinDeSemaine[]=CalendarUtil.getDebutEtFinDeSemaine(dateEncours);
    String idSupport = request.getParameter("idSupport");
    if (idSupport==null){
      idSupport = "SUPP002";
    }
    String idTypeService = request.getParameter("idCategorieIngredient");

    DateTimeFormatter timeFormatter = DateTimeFormatter.ofPattern("HH:mm");
    EtatChiffreAffaire eta = new EtatChiffreAffaire(idSupport, idTypeService, debutEtFinDeSemaine[0], debutEtFinDeSemaine[1]);
    String[] listeDate = eta.getListeDate();
    List<LocalTime[]> listeHoraire = eta.getHoraire();

    // URL du site
    String urlComplete = request.getRequestURL().toString();
    String queryString = request.getQueryString();

    if (queryString != null) {
      urlComplete += "?" + queryString;
    }
    String lienPrecedent = UrlUtils.modifierParametreDansUrl(urlComplete,"d" ,CalendarUtil.castDateToFormat(debutEtFinDeSemaine[2],formatter,DateTimeFormatter.ofPattern("yyyy-MM-dd")));
    String lienSuivant = UrlUtils.modifierParametreDansUrl(urlComplete,"d" ,CalendarUtil.castDateToFormat(debutEtFinDeSemaine[3],formatter,DateTimeFormatter.ofPattern("yyyy-MM-dd")));

    Support [] supports = (Support[]) CGenUtil.rechercher(new Support(),null,null,null,"");
    CategorieIngredient [] categorieIngredients = (CategorieIngredient[]) CGenUtil.rechercher(new CategorieIngredient(),null,null,null,"");

    // Lien vers la grille de diffusion
    String lienGrilleDiffusion = UrlUtils.modifierParametreDansUrl(urlComplete, "but", "reservation/reservation-details-calendrier.jsp");
    
    // Lien vers CA avec Remise
    String lienCARemise = UrlUtils.modifierParametreDansUrl(urlComplete, "but", "reservation/chiffre-affaire-remise-calendrier.jsp");

    String temp="";
    temp=temp+ "<div class=\"modal fade\" id=\"linkModal\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"linkModalLabel\" aria-hidden=\"true\">\r\n" +
            "  <div style='width:60%;background:transparent;' class=\"modal-dialog modal-dialog-centered\" role=\"dialog\">\r\n" +
            "    <div style=\"border-radius: 16px;padding:15px;overflow-y:auto;height:80vh\" class=\"modal-content\">\r\n" +
            "      <div class=\"modal-body\">\r\n"+
            "       <div id=\"modalContent\">\r\n>";
    temp +=                "</div>\r\n" +
            "    </div>\r\n" +
            "   </div>\r\n" +
            "  </div>\r\n" +
            "</div>";
    String bute = "reservation/chiffre-affaire-calendrier.jsp";
%>
<div class="content-wrapper">

  <section class="content-header" style="display: flex; justify-content: space-between; align-items: center;">
    <h1> <i class="fa fa-money"></i>&nbsp;&nbsp;&nbsp; Chiffre d'Affaires TTC par Tranche Horaire</h1>
    <div>
      <a href="<%=lienGrilleDiffusion%>" class="btn btn-primary" style="margin-right: 5px;">
        <i class="fa fa-calendar"></i> Grille de Diffusion
      </a>
      <a href="<%=lienCARemise%>" class="btn btn-success">
        <i class="fa fa-percent"></i> CA avec Remise
      </a>
    </div>
  </section>

  <!-- Navigation semaine -->
  <div class="week-nav">
    <a href="<%=lienPrecedent%>" id="prev-week" class="btn btn-default">
      <i class="fa fa-chevron-left"></i>
    </a>
    <span class="week-range" id="week-range">Semaine du <%=debutEtFinDeSemaine[0]%> au <%=debutEtFinDeSemaine[1]%></span>
    <a href="<%=lienSuivant%>" id="next-week" class="btn btn-default">
      <i class="fa fa-chevron-right"></i>
    </a>
  </div>

  <!-- Sélection du support -->
  <div style="width: 100%;display: flex;justify-content: center">
    <form class="col-md-6 col-xs-12" action="<%=lien%>" method="Get" style="padding: 10px;margin: 5px;border-radius: 5px;display: flex;align-items: end;">
      <div class='form-input col-md-4 col-xs-12'>
        <label class="nopadding fontinter labelinput">Support</label>
        <select class="form-control" name="idSupport">
          <option value="">Tous</option>

          <% for (Support s:supports) {
            String isSelected = "";
            if(idSupport!=null && idSupport.equals(s.getId())){
                isSelected="selected";
              }
          %>
             <option <%=isSelected%> value="<%=s.getId()%>"><%=s.getVal()%></option>
          <% } %>
        </select>

      </div>
      <div class='form-input col-md-4 col-xs-12'>
        <label class="nopadding fontinter labelinput">Type Service</label>
        <select class="form-control" name="idCategorieIngredient">
          <option value="">Tous</option>

          <% for (CategorieIngredient c:categorieIngredients) {
            String isSelected = "";
            if(idTypeService!=null && idTypeService.equals(c.getId())){
              isSelected="selected";
            }
          %>
          <option <%=isSelected%> value="<%=c.getId()%>"><%=c.getVal()%></option>
          <% } %>
        </select>

      </div>
      <div class="form-input col-md-4 col-xs-12">
        <label class="nopadding fontinter labelinput">Date</label>
        <input class='form-control' type='date' value='<%=CalendarUtil.castDateToFormat(dateEncours,formatter,DateTimeFormatter.ofPattern("yyyy-MM-dd"))%>' name='d'>
      </div>
      <input type='hidden' value='<%=bute%>' name='but'>
      <div class="form-input col-md-4 col-xs-12">
        <button class="btn btn-success" style="width: 100%;height: 32px;text-align: center" type="submit">Afficher</button>
      </div>
    </form>
  </div>

  <!-- Total Semaine avec majorations -->
  <div style="width: 100%; display: flex; justify-content: center; align-items: center; margin-bottom: 15px; flex-wrap: wrap;">
    <div class="total-semaine" style="border-radius: 8px; padding: 15px 30px;">
      <i class="fa fa-bar-chart"></i> Total Semaine : <%=Utilitaire.formaterAr(eta.getTotalSemaine())%>
    </div>
    <% if (eta.getTotalMajorationSemaine() > 0) { %>
    <div class="total-majoration">
      <i class="fa fa-clock-o"></i> Majoration Heure Pointe : +<%=Utilitaire.formaterAr(eta.getTotalMajorationSemaine())%>
    </div>
    <div class="total-semaine" style="border-radius: 8px; padding: 15px 30px; background-color: #2e7d32; margin-left: 10px;">
      <i class="fa fa-calculator"></i> Total avec Majoration : <%=Utilitaire.formaterAr(eta.getTotalSemaineAvecMajoration())%>
    </div>
    <% } %>
  </div>

  <section class="content">
    <div class="row">
      <div class="col-xs-12 calendar-scroll">
        <table class="calendar-grid">
          <thead>
          <tr>
            <th class="calendar-cell-title">Horaire</th>
            <% for(int i=0;i<listeDate.length;i++) { %>
            <th class="day-btn" onclick="ouvrirModal(event,'moduleLeger.jsp?but=reservation/inc/chiffre-affaire-popup.jsp&daty=<%=listeDate[i]%>&idSupport=<%=idSupport%>&idCategorieIngredient=<%=idTypeService%>','modalContent')">
              <%=listeDate[i]%>
            </th>
            <% } %>
            <th class="calendar-cell-title" style="background-color: #e3f2fd;">Total Tranche</th>
          </tr>
          </thead>
          <tbody>
          <% for(int i=0;i<listeHoraire.size();i++) {
            LocalTime [] intervales = listeHoraire.get(i);
            double totalTranche = eta.getTotalTranche(intervales);
          %>
          <tr>
            <td class="calendar-cell-title">
              <%=intervales[0].format(timeFormatter)%> - <%=intervales[1].format(timeFormatter)%>
            </td>
            <% for(int j=0;j<listeDate.length;j++) {
              double montantAvecMaj = eta.getChiffreAffaireByTime(intervales, listeDate[j]);
              double majoration = eta.getMajorationByTime(intervales, listeDate[j]);
              double montantBase = montantAvecMaj - majoration;
              int nbResa = eta.getNombreReservationsByTime(intervales, listeDate[j]);
              boolean hasMajoration = majoration > 0;
              String cellClass = montantAvecMaj > 0 ? (hasMajoration ? "calendar-cell has-data has-majoration" : "calendar-cell has-data") : "calendar-cell";
              String montantClass = montantAvecMaj > 0 ? "montant-cell" : "montant-cell zero";
            %>
            <td class="<%=cellClass%>" onclick="ouvrirModal(event,'moduleLeger.jsp?but=reservation/inc/chiffre-affaire-popup.jsp&daty=<%=listeDate[j]%>&heureDebut=<%=intervales[0]%>&heureFin=<%=intervales[1]%>&idSupport=<%=idSupport%>&idCategorieIngredient=<%=idTypeService%>','modalContent')">
              <% if (hasMajoration) { %>
              <div class="<%=montantClass%>" style="color: #e65100;">
                <%=Utilitaire.formaterAr(montantAvecMaj)%>
                
              </div>
              <div style="font-size: 10px; color: #ff9800;">
                +<%=Utilitaire.formaterAr(majoration)%> maj.
              </div>
              <% } else { %>
              <div class="<%=montantClass%>">
                <%=montantAvecMaj > 0 ? Utilitaire.formaterAr(montantAvecMaj) : "-"%>
              </div>
              <% } %>
              <% if(nbResa > 0) { %>
              <div class="nb-reservations">
                <%=nbResa%> diffusion<%=nbResa > 1 ? "s" : ""%>
              </div>
              <% } %>
            </td>
            <% } %>
            <!-- Total de la tranche -->
            <td class="calendar-total-tranche">
              <%=totalTranche > 0 ? Utilitaire.formaterAr(totalTranche) : "-"%>
            </td>
          </tr>
          <% } %>
          </tbody>
          <tfoot>
          <tr>
            <th class="calendar-cell-title" style="background-color: #fff3e0;">TOTAL</th>
            <% for(int k=0;k<listeDate.length;k++) {
              double totalJour = eta.getTotalJour(listeDate[k]);
              double majorationJour = eta.getTotalMajorationJour(listeDate[k]);
              double totalJourAvecMaj = totalJour + majorationJour;
            %>
            <th class="calendar-footer">
              <p style="margin: 0;"><%=Utilitaire.formaterAr(totalJour)%></p>
              <% if (majorationJour > 0) { %>
              <p style="margin: 0; font-size: 11px; color: #e65100;">
                <i class="fa fa-plus-circle"></i> <%=Utilitaire.formaterAr(majorationJour)%>
              </p>
              <p style="margin: 0; font-size: 12px; color: #2e7d32; font-weight: bold;">
                = <%=Utilitaire.formaterAr(totalJourAvecMaj)%>
              </p>
              <% } %>
            </th>
            <% } %>
            <th class="calendar-footer" style="background-color: #1565c0; color: white;">
              <p style="margin: 0;"><%=Utilitaire.formaterAr(eta.getTotalSemaine())%></p>
              <% if (eta.getTotalMajorationSemaine() > 0) { %>
              <p style="margin: 0; font-size: 11px;">
                <i class="fa fa-plus-circle"></i> <%=Utilitaire.formaterAr(eta.getTotalMajorationSemaine())%>
              </p>
              <p style="margin: 0; font-size: 12px; font-weight: bold;">
                = <%=Utilitaire.formaterAr(eta.getTotalSemaineAvecMajoration())%>
              </p>
              <% } %>
            </th>
          </tr>
          </tfoot>
        </table>
      </div>
    </div>
  </section>
</div>

<% out.println(temp);%>

<%
  } catch (Exception e) {
    e.printStackTrace();
  } %>
