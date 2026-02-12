<%--
    Document   : as-commande-analyse
    Created on : 30 d�c. 2016, 04:57:15
    Author     : Joe
--%>
<%@page import="vente.VenteDetailsLib"%>
<%@page import="utilitaire.*"%>
<%@page import="affichage.*"%>
<%@page import="java.util.Calendar"%>
<%@ page import="support.Support" %>
<%@ page import="produits.CategorieIngredient" %>

<%
try{
    VenteDetailsLib mvt = new VenteDetailsLib();
    String nomTable = "VENTE_DETAILS_CPL_MOIS_VISEE";
    mvt.setNomTable(nomTable);

    String listeCrt[] = {"idProduitLib","daty","idSupport","idCategorie"};
    String listeInt[] = {"daty"};
    String[] pourcentage = {};
    String[] colGr = {"idProduitLib"};
    String[] colGrCol = {"mois"};
    //String somDefaut[] = {"qte", "puTotal", "puRevient"};
    String somDefaut[] = {"qte", "puTotal"};

    PageRechercheGroupe pr = new PageRechercheGroupe(mvt, request, listeCrt, listeInt, 3, colGr, somDefaut, pourcentage, colGr.length , somDefaut.length);
    pr.setUtilisateur((user.UserEJB) session.getValue("u"));
    pr.setLien((String) session.getValue("lien"));
    String apreswhere = "";
    String debutSem=Utilitaire.formatterDaty(Utilitaire.getDebutSemaine(Utilitaire.dateDuJourSql())) ;
    Calendar calendar = Calendar.getInstance();
    int month = calendar.get(Calendar.MONTH) + 1; // January is 0
    int year = calendar.get(Calendar.YEAR);
    String dateDebut = String.format("01/%02d/%04d", month, year);
    String dateFin = Utilitaire.dateDuJour();

    if(request.getParameter("daty1")==null&&request.getParameter("daty2")==null)
    apreswhere= "and daty >= TO_DATE('"+dateDebut+"','DD/MM/YYYY') and daty <= TO_DATE('"+dateFin+"','DD/MM/YYYY')";

    String order = "";
    if(request.getParameter("order")!=null && request.getParameter("order").compareToIgnoreCase("")!=0){
        order+= (" "+ request.getParameter("order"));
    }
    String[] grouper = new String[1];
    if(request.getParameter("grouper")!=null && request.getParameter("grouper").compareToIgnoreCase("")!=0){
        grouper[0]=request.getParameter("grouper");
        pr.setColGroupeDefaut(grouper);
    }
    pr.setOrdre(order);
    pr.setAWhere(apreswhere);
    Liste [] listes = new Liste[2];
    Support support = new Support();
    listes[0] = new Liste("idSupport",support,"val","id");
    CategorieIngredient cat = new CategorieIngredient();
    listes[1] = new Liste("idCategorie",cat,"val","id");
    pr.getFormu().changerEnChamp(listes);
    pr.getFormu().getChamp("daty1").setDefaut(dateDebut);
    pr.getFormu().getChamp("daty2").setDefaut(dateFin);
    pr.getFormu().getChamp("daty1").setLibelle("Date Min");
    pr.getFormu().getChamp("daty2").setLibelle("Date max");
    pr.getFormu().getChamp("idCategorie").setLibelle("Type de service");
    pr.getFormu().getChamp("idSupport").setLibelle("Support");
    pr.getFormu().getChamp("idProduitLib").setLibelle("Nom de service");
    pr.getFormu().getChamp("idProduitLib").setVisible(false);

    pr.setNpp(500);
    pr.setApres("vente/vente-analyse.jsp");
    pr.creerObjetPageCroise(colGrCol,pr.getLien()+"?but=");
%>
<script>
    function changerDesignation() {
        document.analyse.submit();
    }
    $(document).ready(function() {
        $('.box table tr').each(function() {
            $(this).find('td:last, th:last').hide();
        });
        
        // Ajouter les totaux par ligne et par colonne
        addTotalsToTable();
    });
    
    function addTotalsToTable() {
        const table = document.querySelector('.box table');
        if (!table) return;
        
        const tbody = table.querySelector('tbody');
        const thead = table.querySelector('thead');
        if (!tbody || !thead) return;
        
        const rows = tbody.querySelectorAll('tr');
        const headerRow = thead.querySelector('tr');
        if (!headerRow) return;
        
        // Ajouter l'en-tête "TOTAL" 
        const totalHeader = document.createElement('th');
        totalHeader.textContent = 'TOTAL';
        totalHeader.style.textAlign = 'right';
        totalHeader.style.fontWeight = 'bold';
        totalHeader.style.backgroundColor = '#f5f5f5';
        headerRow.appendChild(totalHeader);
        
        // Calculer le nombre de colonnes de données (sans la première colonne de libellé)
        const numDataCols = headerRow.querySelectorAll('th').length - 2; // -1 pour libellé, -1 pour le nouveau TOTAL
        
        // Tableaux pour stocker les totaux par colonne (qte et puTotal alternés)
        const colTotals = [];
        for (let i = 0; i < numDataCols; i++) {
            colTotals.push(0);
        }
        
        // Pour chaque ligne, calculer le total et ajouter une cellule
        rows.forEach((row) => {
            const cells = row.querySelectorAll('td');
            if (cells.length <= 1) return;
            
            let rowTotalQte = 0;
            let rowTotalMontant = 0;
            
            // Parcourir les cellules de données (en sautant la première qui est le libellé)
            for (let i = 1; i < cells.length; i++) {
                const cellText = cells[i].textContent.trim();
                const lines = cellText.split('\n').map(s => s.trim()).filter(s => s !== '');
                
                lines.forEach((line, lineIndex) => {
                    const value = parseFloat(line.replace(/\s/g, '').replace(',', '.')) || 0;
                    if (lineIndex === 0) {
                        rowTotalQte += value;
                    } else if (lineIndex === 1) {
                        rowTotalMontant += value;
                    }
                    // Ajouter aux totaux de colonne
                    const colIndex = (i - 1) * 2 + lineIndex;
                    if (colIndex < colTotals.length * 2) {
                        if (lineIndex === 0) {
                            colTotals[(i - 1) * 2] = (colTotals[(i - 1) * 2] || 0) + value;
                        } else {
                            colTotals[(i - 1) * 2 + 1] = (colTotals[(i - 1) * 2 + 1] || 0) + value;
                        }
                    }
                });
            }
            
            // Ajouter la cellule total pour cette ligne
            const totalCell = document.createElement('td');
            totalCell.style.textAlign = 'right';
            totalCell.style.fontWeight = 'bold';
            totalCell.style.backgroundColor = '#f0f8ff';
            totalCell.innerHTML = formatNumber(rowTotalQte) + '<br>' + formatNumber(rowTotalMontant);
            row.appendChild(totalCell);
        });
        
        // Ajouter une ligne de totaux en bas
        const totalRow = document.createElement('tr');
        totalRow.style.fontWeight = 'bold';
        totalRow.style.backgroundColor = '#e8e8e8';
        
        // Première cellule: "TOTAL"
        const labelCell = document.createElement('td');
        labelCell.textContent = 'TOTAL';
        labelCell.style.textAlign = 'center';
        labelCell.style.fontWeight = 'bold';
        totalRow.appendChild(labelCell);
        
        // Calculer et ajouter les totaux par colonne
        let grandTotalQte = 0;
        let grandTotalMontant = 0;
        
        for (let i = 0; i < numDataCols; i++) {
            const qteTotal = colTotals[i * 2] || 0;
            const montantTotal = colTotals[i * 2 + 1] || 0;
            grandTotalQte += qteTotal;
            grandTotalMontant += montantTotal;
            
            const cell = document.createElement('td');
            cell.style.textAlign = 'right';
            cell.innerHTML = formatNumber(qteTotal) + '<br>' + formatNumber(montantTotal);
            totalRow.appendChild(cell);
        }
        
        // Cellule grand total
        const grandTotalCell = document.createElement('td');
        grandTotalCell.style.textAlign = 'right';
        grandTotalCell.style.backgroundColor = '#d4edda';
        grandTotalCell.innerHTML = '<strong>' + formatNumber(grandTotalQte) + '</strong><br><strong>' + formatNumber(grandTotalMontant) + '</strong>';
        totalRow.appendChild(grandTotalCell);
        
        tbody.appendChild(totalRow);
    }
    
    function formatNumber(num) {
        return num.toLocaleString('fr-FR', {minimumFractionDigits: 2, maximumFractionDigits: 2});
    }
    
    function alignTableCells() {
        const tbody = document.querySelector('tbody');
        if (!tbody) return;

        const rows = tbody.querySelectorAll('tr');

        rows.forEach((row) => {
            const cells = row.querySelectorAll('td');
            if (cells.length > 0) {
                cells[0].style.textAlign = 'center';
                cells[0].style.verticalAlign = 'middle';
            }
            if (cells.length > 1) {
                cells[1].style.textAlign = 'right';
            }
        });
    }
    document.addEventListener('DOMContentLoaded', alignTableCells);
</script>
<div class="content-wrapper">
    <section class="content-header">
        <h1>Analyse de rentabilit&eacute; de service de diffusion</h1>
    </section>
    <section class="content">
        <form action="<%=pr.getLien()%>?but=vente/vente-analyse.jsp" method="post" name="analyse" id="analyse">
            <%out.println(pr.getFormu().getHtmlEnsemble());%>
        </form>
        <ul>
            <li>La premi&egrave;re ligne correspond &agrave; la quantit&eacute;</li>
            <li>La 2&egrave;me ligne correspond au montant total</li>
        </ul>
           <%
            String lienTableau[] = {};
            pr.getTableau().setLien(lienTableau);
            pr.getTableau().setColonneLien(somDefaut);%>
        <br>
        <%
            out.println(pr.getTableau().getHtml());
            out.println(pr.getBasPage());
        %>
    </section>
</div>
<%
    }catch(Exception e){
        e.printStackTrace();
    }
%>
