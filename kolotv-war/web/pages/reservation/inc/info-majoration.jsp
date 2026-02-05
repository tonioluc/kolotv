<%--
  Component: info-majoration.jsp
  Description: Affiche les informations sur la majoration d'heure de pointe pour une réservation
  Usage: <jsp:include page="inc/info-majoration.jsp"><jsp:param name="resId" value="<%= resId %>"/></jsp:include>
--%>
<%@ page import="heurepointe.HeurePointeUtils" %>
<%@ page import="heurepointe.HeurePointeUtils.DetailMajoration" %>
<%@ page import="heurepointe.HeurePointeUtils.DetailHeurePointe" %>
<%@ page import="reservation.ReservationDetailsAvecDiffusion" %>
<%@ page import="reservation.EtatReservationDetails" %>
<%@ page import="utilitaire.Utilitaire" %>
<%@ page import="utilitaire.UtilDB" %>
<%@ page import="bean.CGenUtil" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.util.List" %>

<%
    try {
        String resId = request.getParameter("resId");
        String heureParam = request.getParameter("heure");
        String dureeParam = request.getParameter("duree");
        String idSupportParam = request.getParameter("idSupport");
        String montantParam = request.getParameter("montant");
        
        Connection c = null;
        DetailMajoration detail = null;
        
        try {
            c = new UtilDB().GetConn();
            
            if (resId != null && !resId.isEmpty()) {
                // Récupérer la réservation depuis la base
                ReservationDetailsAvecDiffusion res = new ReservationDetailsAvecDiffusion();
                res.setId(resId);
                ReservationDetailsAvecDiffusion[] results = (ReservationDetailsAvecDiffusion[]) CGenUtil.rechercher(res, null, null, c, "");
                
                if (results != null && results.length > 0) {
                    detail = EtatReservationDetails.getDetailMajoration(results[0], c);
                }
            } else if (heureParam != null && dureeParam != null && montantParam != null) {
                // Utiliser les paramètres directs
                long dureeSecondes = Long.parseLong(dureeParam);
                double montant = Double.parseDouble(montantParam);
                detail = HeurePointeUtils.calculerDetailMajoration(montant, heureParam, dureeSecondes, idSupportParam, c);
            }
            
        } finally {
            if (c != null) {
                c.close();
            }
        }
        
        if (detail != null && detail.estMajore()) {
%>
<div class="info-majoration" style="background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%); border-radius: 8px; padding: 10px; margin: 10px 0; color: white;">
    <div style="display: flex; align-items: center; margin-bottom: 8px;">
        <i class="fa fa-clock-o" style="font-size: 20px; margin-right: 8px;"></i>
        <strong>Majoration Heure de Pointe</strong>
    </div>
    
    <div style="display: flex; justify-content: space-between; font-size: 12px;">
        <div>
            <p style="margin: 2px 0;">Prix de base: <strong><%=Utilitaire.formaterAr(detail.getPrixBase())%></strong></p>
            <p style="margin: 2px 0;">Majoration: <strong>+<%=Utilitaire.formaterAr(detail.getMontantMajoration())%></strong> 
                (<%= String.format("%.1f", detail.getPourcentageMajorationEffectif()) %>%)</p>
        </div>
        <div style="text-align: right;">
            <p style="margin: 2px 0;">Dur&eacute;e en heure de pointe: <strong><%= detail.getDureeEnHeurePointe() / 60 %>mn <%= detail.getDureeEnHeurePointe() % 60 %>s</strong></p>
            <p style="margin: 2px 0; font-size: 16px; font-weight: bold;">Total: <%=Utilitaire.formaterAr(detail.getPrixFinal())%></p>
        </div>
    </div>
    
    <% 
        List<DetailHeurePointe> detailsHP = detail.getDetailsHeuresPointe();
        if (detailsHP != null && !detailsHP.isEmpty()) {
    %>
    <div style="margin-top: 8px; border-top: 1px solid rgba(255,255,255,0.3); padding-top: 8px;">
        <small>D&eacute;tail des majorations:</small>
        <ul style="margin: 5px 0; padding-left: 20px; font-size: 11px;">
            <% for (DetailHeurePointe hp : detailsHP) { %>
            <li><%= hp.getDesignation() %>: +<%= String.format("%.0f", hp.getPourcentage()) %>% pendant <%= hp.getDuree() / 60 %>mn <%= hp.getDuree() % 60 %>s = +<%=Utilitaire.formaterAr(hp.getMontant())%></li>
            <% } %>
        </ul>
    </div>
    <% } %>
</div>
<%
        } else if (detail != null) {
%>
<div class="info-majoration" style="background: #e8f5e9; border-radius: 8px; padding: 8px; margin: 10px 0; color: #2e7d32; font-size: 12px;">
    <i class="fa fa-check-circle" style="margin-right: 5px;"></i>
    Aucune majoration d'heure de pointe appliqu&eacute;e
</div>
<%
        }
    } catch (Exception e) {
        // En cas d'erreur, ne rien afficher pour ne pas casser l'interface
        // e.printStackTrace();
    }
%>
