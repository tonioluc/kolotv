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
    String nomTable = "VENTE_DETAILS_CPL_2_VISEE";
    mvt.setNomTable(nomTable);

    String listeCrt[] = {"idProduitLib","daty","idSupport","idCategorie"};
    String listeInt[] = {"daty"};
    String[] pourcentage = {};
    String[] colGr = {"idProduitLib"};
    String[] colGrCol = {"moisAnnee"};
    //String somDefaut[] = {"qte", "puTotal", "puRevient"};
    String somDefaut[] = {"puTotal"};

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
        order= (" "+ request.getParameter("order"));
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

        setTimeout(function() {
            styleExistingTotals();
        }, 100);
    });
    
    function styleExistingTotals() {

        let table = document.querySelector('.box table');
        if (!table) table = document.querySelector('.content table');
        if (!table) table = document.querySelector('table');
        if (!table) return;
        

        const tbody = table.querySelector('tbody');
        const thead = table.querySelector('thead');
        
        let rows, headerRow;
        if (tbody && thead) {
            rows = Array.from(tbody.querySelectorAll('tr'));
            headerRow = thead.querySelector('tr');
        } else {
            const allRows = table.querySelectorAll('tr');
            if (allRows.length < 2) return;
            headerRow = allRows[0];
            rows = Array.from(allRows).slice(1);
        }
        
        if (!headerRow || rows.length === 0) return;
        
        // Renommer les en-têtes vides
        const headerCells = Array.from(headerRow.querySelectorAll('th'));
        headerCells.forEach((th, index) => {
            if (index > 0 && th.textContent.trim() === '') {
                // Dernière colonne = TOTAL LIGNE, sinon TOTAL
                if (index === headerCells.length - 1) {
                    th.textContent = 'TOTAL LIGNE';
                    th.style.cssText = 'background-color:#28a745;color:white;font-weight:bold;text-align:center;padding:10px;';
                } else {
                    th.textContent = 'TOTAL';
                    th.style.cssText = 'background-color:#17a2b8;color:white;font-weight:bold;text-align:center;padding:10px;';
                }
            }
        });
        
        // Trouver la dernière ligne (ligne de total colonne)
        const lastRow = rows[rows.length - 1];
        const lastRowCells = lastRow.querySelectorAll('td');
        
        // Vérifier si c'est une ligne de total (première cellule vide)
        if (lastRowCells.length > 0 && lastRowCells[0].textContent.trim() === '') {
            // C'est la ligne de total colonne
            lastRowCells[0].textContent = 'TOTAL';
            lastRowCells[0].style.cssText = 'font-weight:bold;text-align:center;background-color:#007bff;color:white;padding:10px;';
            
            // Calculer le grand total à partir des totaux de ligne
            let grandTotal = 0;
            for (let r = 0; r < rows.length - 1; r++) {
                const cells = rows[r].querySelectorAll('td');
                if (cells.length > 0) {
                    const lastCell = cells[cells.length - 1];
                    const cellText = lastCell.textContent.replace(/\s/g, '').replace(/,/g, '.').replace(/[^\d.-]/g, '');
                    grandTotal += parseFloat(cellText) || 0;
                }
            }
            
            // Styliser les cellules de total colonne
            for (let i = 1; i < lastRowCells.length; i++) {
                if (i === lastRowCells.length - 1) {
                    // Dernière cellule = grand total avec valeur
                    lastRowCells[i].textContent = grandTotal.toLocaleString('fr-FR', {minimumFractionDigits: 2, maximumFractionDigits: 2});
                    lastRowCells[i].style.cssText = 'text-align:right;font-weight:bold;background-color:#dc3545;color:white;padding:10px 12px;font-size:1.1em;';
                } else {
                    // Autres cellules de total colonne
                    lastRowCells[i].style.cssText = 'text-align:right;font-weight:bold;background-color:#cce5ff;color:#004085;padding:8px 12px;';
                }
            }
        }
        
        // Styliser les cellules de total ligne (dernière colonne de chaque ligne sauf la dernière)
        for (let r = 0; r < rows.length - 1; r++) {
            const cells = rows[r].querySelectorAll('td');
            if (cells.length > 0) {
                const lastCell = cells[cells.length - 1];
                lastCell.style.cssText = 'font-weight:bold;text-align:right;background-color:#d4edda;color:#155724;padding:8px 12px;';
                
                // Aligner les autres cellules à droite
                for (let i = 1; i < cells.length - 1; i++) {
                    cells[i].style.textAlign = 'right';
                    cells[i].style.padding = '8px 12px';
                }
            }
        }

    }
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
            <li>Chaque cellule repr&eacute;sente le montant total par mois (format MM/AA)</li>
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
