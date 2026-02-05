<%--
  Page: Chiffre d'affaires avec Remise par tranche horaire
  Description: Affiche le chiffre d'affaires avec remise par tranche horaire (00h-23h) sous forme de calendrier hebdomadaire
--%>
<%@ page import="affichage.*" %>
<%@page import="java.util.Map"%>
<%@page import="java.util.HashMap"%>
<%@ page import="reservation.EtatChiffreAffaireRemise" %>
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
  background-color: #fff3e0;
  box-shadow: inset 0 0 5px rgba(230,81,0,0.2);
}
.calendar-cell.has-data {
  background-color: #fff8e1;
}
.calendar-cell.has-data:hover {
  background-color: #ffecb3;
}

.day-btn {
  cursor: pointer;
  color: white;
  background-color: #e65100;
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
  background-color: #bf360c;
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
  background-color: #ffe0b2;
  font-weight: bold;
  text-align: center;
}

.montant-cell {
  font-size: 14px;
  font-weight: bold;
  color: #e65100;
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
  background-color: #e65100;
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
  color: #e65100;
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
    EtatChiffreAffaireRemise eta = new EtatChiffreAffaireRemise(idSupport, idTypeService, debutEtFinDeSemaine[0], debutEtFinDeSemaine[1]);
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
    
    // Lien vers CA TTC
    String lienCATTC = UrlUtils.modifierParametreDansUrl(urlComplete, "but", "reservation/chiffre-affaire-calendrier.jsp");

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
    String bute = "reservation/chiffre-affaire-remise-calendrier.jsp";
%>
<div class="content-wrapper">

  <section class="content-header" style="display: flex; justify-content: space-between; align-items: center;">
    <h1> <i class="fa fa-percent"></i>&nbsp;&nbsp;&nbsp; Chiffre d'Affaires avec Remise par Tranche Horaire</h1>
    <div>
      <a href="<%=lienGrilleDiffusion%>" class="btn btn-primary" style="margin-right: 5px;">
        <i class="fa fa-calendar"></i> Grille de Diffusion
      </a>
      <a href="<%=lienCATTC%>" class="btn btn-info">
        <i class="fa fa-money"></i> CA TTC
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
        <button class="btn btn-warning" style="width: 100%;height: 32px;text-align: center" type="submit">Afficher</button>
      </div>
    </form>
  </div>

  <!-- Total Semaine -->
  <div style="width: 100%; display: flex; justify-content: center; margin-bottom: 15px;">
    <div class="total-semaine" style="border-radius: 8px; padding: 15px 30px;">
      <i class="fa fa-bar-chart"></i> Total Semaine (avec Remise) : <%=Utilitaire.formaterAr(eta.getTotalSemaine())%>
    </div>
  </div>

  <section class="content">
    <div class="row">
      <div class="col-xs-12 calendar-scroll">
        <table class="calendar-grid">
          <thead>
          <tr>
            <th class="calendar-cell-title">Horaire</th>
            <% for(int i=0;i<listeDate.length;i++) { %>
            <th class="day-btn" onclick="ouvrirModal(event,'moduleLeger.jsp?but=reservation/inc/chiffre-affaire-remise-popup.jsp&daty=<%=listeDate[i]%>&idSupport=<%=idSupport%>&idCategorieIngredient=<%=idTypeService%>','modalContent')">
              <%=listeDate[i]%>
            </th>
            <% } %>
            <th class="calendar-cell-title" style="background-color: #ffe0b2;">Total Tranche</th>
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
              double montant = eta.getChiffreAffaireByTime(intervales, listeDate[j]);
              int nbResa = eta.getNombreReservationsByTime(intervales, listeDate[j]);
              String cellClass = montant > 0 ? "calendar-cell has-data" : "calendar-cell";
              String montantClass = montant > 0 ? "montant-cell" : "montant-cell zero";
            %>
            <td class="<%=cellClass%>" onclick="ouvrirModal(event,'moduleLeger.jsp?but=reservation/inc/chiffre-affaire-remise-popup.jsp&daty=<%=listeDate[j]%>&heureDebut=<%=intervales[0]%>&heureFin=<%=intervales[1]%>&idSupport=<%=idSupport%>&idCategorieIngredient=<%=idTypeService%>','modalContent')">
              <div class="<%=montantClass%>">
                <%=montant > 0 ? Utilitaire.formaterAr(montant) : "-"%>
              </div>
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
            %>
            <th class="calendar-footer">
              <p style="margin: 0;"><%=Utilitaire.formaterAr(totalJour)%></p>
            </th>
            <% } %>
            <th class="calendar-footer" style="background-color: #e65100; color: white;">
              <p style="margin: 0;"><%=Utilitaire.formaterAr(eta.getTotalSemaine())%></p>
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
