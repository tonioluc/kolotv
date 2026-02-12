-- Vue pour l'analyse des ventes avec regroupement par mois
-- Ajoute une colonne MOIS au format 'MM/YYYY' pour permettre le regroupement mensuel

CREATE OR REPLACE VIEW VENTE_DETAILS_CPL_MOIS_VISEE AS
SELECT vd.ID,
       vd.IDVENTE,
       v.DESIGNATION          AS IDVENTELIB,
       vd.IDPRODUIT ,
       i.LIBELLE              AS IDPRODUITLIB,
       vd.IDORIGINE,
       vd.QTE,
       nvl(vd.PU, 0)          AS PU,
       CAST(nvl((vd.PU * vd.QTE)-nvl(vd.REMISE,0), 0) +nvl(((vd.PU * vd.QTE)-nvl(vd.REMISE,0)) * (vd.TVA/100), 0) AS number(30,2)) AS puTotal,
       CAST(nvl(vd.PUACHAT * vd.QTE, 0) AS number(30,2)) AS puTotalAchat,
       CAST(nvl(vd.PU * vd.QTE, 0) - nvl(vd.PUACHAT * vd.QTE, 0) AS number(30,2)) AS puRevient,
       c.ID  AS IDCATEGORIE,
       c.VAL AS IDCATEGORIELIB,
       v.DATY AS daty,
       TO_CHAR(v.DATY, 'MM/YYYY') AS MOIS,
       m.ID AS IDMAGASIN,
       m.VAL AS IDMAGASINLIB,
       p1.ID AS IDPOINT,
       p1.VAL AS IDPOINTLIB,
       vd.IDDEVISE,
       vd.IDDEVISE AS IDDEVISELIB,
       cast(nvl((CAST(nvl(vd.PU * vd.QTE*(1-nvl(vd.REMISE,0)/100), 0) +nvl(vd.PU * vd.QTE*(1-nvl(vd.REMISE,0)/100) *(vd.TVA/100), 0) AS number(30,2))-(vd.QTE*vd.PUREVIENT)),0) as number(20,2)) as margeBrute,
       v.IDRESERVATION,
       s.ID AS IDSUPPORT,
       s.VAL AS IDSUPPORTLIB
FROM VENTE_DETAILS vd
         LEFT JOIN VENTE v ON v.ID = vd.IDVENTE
         LEFT JOIN MAGASIN m ON m.ID = v.IDMAGASIN
         LEFT JOIN AS_INGREDIENTS i ON i.ID = vd.IDPRODUIT
         LEFT JOIN POINT p1 ON p1.ID = m.IDPOINT
         LEFT JOIN CATEGORIEINGREDIENT c  ON i.CATEGORIEINGREDIENT  = c.ID
         LEFT JOIN SUPPORT s ON s.ID = i.IDSUPPORT
WHERE v.ETAT >= 11;
commit;
