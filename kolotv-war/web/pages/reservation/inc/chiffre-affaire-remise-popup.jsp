<%--
  Popup: Détails du chiffre d'affaires avec remise
  Description: Affiche les détails des réservations pour une date/tranche horaire donnée avec le montant avec remise
--%>
<%@page import="vente.VenteDetailsLib"%>
<%@ page import="bean.*" %>
<%@ page import="affichage.*" %>
<%@ page import="reservation.ReservationDetailsLib" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="reservation.ReservationDetailsAvecDiffusion" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="reservation.Reservation" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="utilitaire.Utilitaire" %>


<%
    try{
        String lien = (String) session.getValue("lien");
        user.UserEJB u= (user.UserEJB) session.getValue("u");

        ReservationDetailsAvecDiffusion t = new ReservationDetailsAvecDiffusion();
        String bute = "reservation/chiffre-affaire-remise-calendrier.jsp";
        if (request.getParameter("bute")!=null){
            bute = request.getParameter("bute");
        }
        String titre = "Détails du CA avec Remise";
        String awhere = "";
        double montantTotal = 0;
        double montantRemiseTotal = 0;
        
        if(request.getParameter("daty") != null){
            String daty = request.getParameter("daty");
            String idSupport = request.getParameter("idSupport");
            String idCategorieIngredient = request.getParameter("idCategorieIngredient");
            titre = "CA avec Remise du " + daty;
            awhere = " and DATY = TO_DATE('"+daty+"','DD/MM/YYYY')\n";
            if (request.getParameter("heureDebut") != null && request.getParameter("heureFin") != null){
                String hDebut = request.getParameter("heureDebut");
                String hFin = request.getParameter("heureFin");
                awhere += " AND TO_DATE(HEURE,'HH24:MI:SS') >= TO_DATE('"+hDebut+"','HH24:MI:SS')\n" +
                        "  AND TO_DATE(HEURE,'HH24:MI:SS') < TO_DATE('"+hFin+"','HH24:MI:SS')";
                titre = "CA avec Remise du " + daty + " (" + hDebut + " - " + hFin + ")";
            }
            if (idSupport!=null && !idSupport.isEmpty() && !idSupport.equals("null")){
                awhere += " and idSupport = '"+idSupport+"'";
            }
            if (idCategorieIngredient!=null && !idCategorieIngredient.isEmpty() && !idCategorieIngredient.equals("null")){
                awhere += " and CATEGORIEPRODUIT = '"+idCategorieIngredient+"'";
            }
        }

        ReservationDetailsAvecDiffusion [] resa = (ReservationDetailsAvecDiffusion[]) CGenUtil.rechercher(t,null,null,null,awhere+" ORDER BY HEURE ASC ");
        List<ReservationDetailsAvecDiffusion> list = Reservation.trierResa(Arrays.asList(resa),null);
        
        // Calculer les montants totaux
        for (ReservationDetailsAvecDiffusion r : list) {
            montantTotal += (r.getMontantTtc() - r.getMontantRemise());
            montantRemiseTotal += r.getMontantRemise();
        }
%>
    <div class="content-wrapper">
        <section class="content-header">
            <h1><i class="fa fa-percent"></i> <%=titre%></h1>
        </section>
        <section class="content">
            <div class="row">
                <div class="row col-md-12">
                    <!-- Résumé du montant -->
                    <div class="box" style="padding: 15px; background: linear-gradient(135deg, #e65100 0%, #bf360c 100%); border-radius: 16px; margin-bottom: 15px; color: white;">
                        <div style="display: flex; justify-content: space-between; align-items: center;">
                            <div>
                                <h3 style="margin: 0; font-size: 16px;">Montant Total (avec Remise)</h3>
                                <p style="margin: 5px 0 0 0; font-size: 28px; font-weight: bold;"><%=Utilitaire.formaterAr(montantTotal)%></p>
                            </div>
                            <div style="text-align: right;">
                                <p style="margin: 0; font-size: 14px;"><%=list.size()%> diffusion<%=list.size() > 1 ? "s" : ""%></p>
                                <p style="margin: 5px 0 0 0; font-size: 12px; opacity: 0.9;">Remise totale: <%=Utilitaire.formaterAr(montantRemiseTotal)%></p>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Tableau des détails -->
                    <div class="box" style="padding: 15px;background-color: white;border-radius: 16px;">
                        <div class="box-body table-responsive no-padding" style="overflow-y: auto;height: 50vh">
                            <div id="selectnonee">
                                <table width="100%" border="0" align="center" cellpadding="3" cellspacing="3" class="table table-hover" style="font-size: 14px;">
                                    <thead>
                                    <tr class="head">
                                        <th width="5%" align="center" valign="top" style="background-color:#ffe0b2">
                                            #
                                        </th>
                                        <th width="12%" align="center" valign="top" style="background-color:#ffe0b2">
                                            <a>Remarque</a>
                                        </th>
                                        <th width="8%" align="center" valign="top" style="background-color:#ffe0b2">
                                            <a>Heure</a>
                                        </th>
                                        <th width="10%" align="center" valign="top" style="background-color:#ffe0b2">
                                            <a>Client</a>
                                        </th>
                                        <th width="10%" align="center" valign="top" style="background-color:#ffe0b2">
                                            <a>M&eacute;dia</a>
                                        </th>
                                        <th width="8%" align="center" valign="top" style="background-color:#ffe0b2">
                                            <a>Dur&eacute;e</a>
                                        </th>
                                        <th width="10%" align="center" valign="top" style="background-color:#ffe0b2">
                                            <a>Montant TTC</a>
                                        </th>
                                        <th width="10%" align="center" valign="top" style="background-color:#ffe0b2; color: #d32f2f;">
                                            <a><strong>Remise</strong></a>
                                        </th>
                                        <th width="12%" align="center" valign="top" style="background-color:#ffe0b2; color: #e65100;">
                                            <a><strong>Net &agrave; payer</strong></a>
                                        </th>
                                        <th width="8%" align="center" valign="top" style="background-color:#ffe0b2">
                                            <a>Etat</a>
                                        </th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                        <% int index = 1;
                                        for (ReservationDetailsAvecDiffusion r:list){ 
                                            double netAPayer = r.getMontantTtc() - r.getMontantRemise();
                                        %>
                                            <tr onmouseover="this.style.backgroundColor='#EAEAEA'" onmouseout="this.style.backgroundColor=''" style="cursor: pointer;" onclick="window.open('<%=lien%>?but=reservation/reservation-details-fiche.jsp&id=<%=r.getId()%>', '_blank')">
                                                <td width="5%" align="center">
                                                    <%=index++%>
                                                </td>
                                                <td width="12%" align="left" style="background-color: <%=r.getBackGround()%>"><%=(r.getRemarque() != null) ? r.getRemarque() : ""%></td>
                                                <td width="8%" align="left"><%=r.getHeure()%></td>
                                                <td width="10%" align="left"><%=r.getClient()%></td>
                                                <td width="10%" align="left" style="background-color: <%=r.getBackGround()%>"><%=(r.getLibellemedia() != null) ? r.getLibellemedia() : ""%></td>
                                                <td width="8%" align="left"><%=r.getDuree()%>s</td>
                                                <td width="10%" align="right" style="color: #757575;">
                                                    <%=Utilitaire.formaterAr(r.getMontantTtc())%>
                                                </td>
                                                <td width="10%" align="right" style="color: #d32f2f;">
                                                    <% if(r.getMontantRemise() > 0) { %>
                                                        -<%=Utilitaire.formaterAr(r.getMontantRemise())%>
                                                    <% } else { %>
                                                        -
                                                    <% } %>
                                                </td>
                                                <td width="12%" align="right" style="font-weight: bold; color: #e65100;">
                                                    <%=Utilitaire.formaterAr(netAPayer)%>
                                                </td>
                                                <td width="8%" align="left"><%=r.getEtatDiffusion()%></td>
                                            </tr>
                                        <% } %>
                                    </tbody>
                                    <tfoot>
                                        <tr style="background-color: #ffe0b2; font-weight: bold;">
                                            <td colspan="6" align="right" style="padding: 10px;">
                                                <strong>TOTAL :</strong>
                                            </td>
                                            <td align="right" style="padding: 10px; color: #757575;">
                                                <%=Utilitaire.formaterAr(montantTotal + montantRemiseTotal)%>
                                            </td>
                                            <td align="right" style="padding: 10px; color: #d32f2f;">
                                                -<%=Utilitaire.formaterAr(montantRemiseTotal)%>
                                            </td>
                                            <td align="right" style="padding: 10px; color: #e65100; font-size: 16px;">
                                                <strong><%=Utilitaire.formaterAr(montantTotal)%></strong>
                                            </td>
                                            <td></td>
                                        </tr>
                                    </tfoot>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    </div>

<%
    }catch(Exception e){
        e.printStackTrace();
    }
%>
