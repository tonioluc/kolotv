-- Script de création de la table HeureDePointe
-- Date: 05/02/2026
-- Description: Table pour gérer les heures de pointe avec majoration de prix

-- Création de la séquence
CREATE SEQUENCE SEQ_HEUREDEPOINTE START WITH 1 INCREMENT BY 1;

-- Création de la table
CREATE TABLE HEUREDEPOINTE (
    ID VARCHAR2(50) PRIMARY KEY,
    JOUR NUMBER(1) NOT NULL,           -- 1=Lundi, 2=Mardi, ..., 7=Dimanche
    HEUREDEBUT VARCHAR2(10) NOT NULL,  -- Format HH:mm:ss
    HEUREFIN VARCHAR2(10) NOT NULL,    -- Format HH:mm:ss
    POURCENTAGEMAJORATION NUMBER(5,2) DEFAULT 10,  -- Pourcentage de majoration (ex: 10 pour 10%)
    IDSUPPORT VARCHAR2(50),            -- Support concerné (NULL = tous les supports)
    LIBELLE VARCHAR2(200),             -- Description de l'heure de pointe
    ETAT NUMBER(2) DEFAULT 0,
    CONSTRAINT CHK_JOUR CHECK (JOUR BETWEEN 1 AND 7),
    CONSTRAINT CHK_POURCENTAGE CHECK (POURCENTAGEMAJORATION >= 0)
);

-- Création de la vue complémentaire
CREATE OR REPLACE VIEW HEUREDEPOINTE_CPL AS
SELECT 
    h.*,
    CASE h.JOUR 
        WHEN 1 THEN 'Lundi'
        WHEN 2 THEN 'Mardi'
        WHEN 3 THEN 'Mercredi'
        WHEN 4 THEN 'Jeudi'
        WHEN 5 THEN 'Vendredi'
        WHEN 6 THEN 'Samedi'
        WHEN 7 THEN 'Dimanche'
    END AS JOURLIBELLE,
    s.VAL AS SUPPORTLIBELLE
FROM HEUREDEPOINTE h
LEFT JOIN SUPPORT s ON h.IDSUPPORT = s.ID;

-- Fonction pour générer l'ID
CREATE OR REPLACE FUNCTION GETSEQHEUREDEPOINTE RETURN VARCHAR2 AS
    v_seq NUMBER;
BEGIN
    SELECT SEQ_HEUREDEPOINTE.NEXTVAL INTO v_seq FROM DUAL;
    RETURN v_seq;
END;
/

-- Insertion des données d'exemple (heures de pointe)
-- Lundi 12h-14h avec majoration de 10%
INSERT INTO HEUREDEPOINTE (ID, JOUR, HEUREDEBUT, HEUREFIN, POURCENTAGEMAJORATION, LIBELLE, ETAT) 
VALUES ('HDP' || LPAD(SEQ_HEUREDEPOINTE.NEXTVAL, 6, '0'), 1, '10:00:00', '11:00:00', 10, 'Lundi midi - Heure de pointe', 5);

-- Lundi 16h-19h avec majoration de 10%
INSERT INTO HEUREDEPOINTE (ID, JOUR, HEUREDEBUT, HEUREFIN, POURCENTAGEMAJORATION, LIBELLE, ETAT) 
VALUES ('HDP' || LPAD(SEQ_HEUREDEPOINTE.NEXTVAL, 6, '0'), 1, '06:00:00', '07:00:00', 10, 'Lundi après-midi - Heure de pointe', 5);

-- Samedi 08h-15h avec majoration de 10%
INSERT INTO HEUREDEPOINTE (ID, JOUR, HEUREDEBUT, HEUREFIN, POURCENTAGEMAJORATION, LIBELLE, ETAT) 
VALUES ('HDP' || LPAD(SEQ_HEUREDEPOINTE.NEXTVAL, 6, '0'), 6, '08:00:00', '15:00:00', 10, 'Samedi matin - Heure de pointe', 5);

COMMIT;

-- ============================================
-- Ajout du menu pour accéder à la gestion des Heures de Pointe
-- ============================================

-- Menu principal "Heures de Pointe" sous Configurations (MNDT150500134001)
INSERT INTO menudynamique (id, libelle, icone, href, rang, niveau, id_pere) 
VALUES ('MENUDYN_HDP001', 'Heures de Pointe', 'fa fa-clock-o', '#', 10, 2, 'MNDT150500134001');

-- Sous-menu: Liste des heures de pointe
INSERT INTO menudynamique (id, libelle, icone, href, rang, niveau, id_pere) 
VALUES ('MENUDYN_HDP002', 'Liste', 'fa fa-list', 'module.jsp?but=heuredepointe/heuredepointe-liste.jsp', 1, 3, 'MENUDYN_HDP001');

-- Sous-menu: Ajouter une heure de pointe
INSERT INTO menudynamique (id, libelle, icone, href, rang, niveau, id_pere) 
VALUES ('MENUDYN_HDP003', 'Ajouter', 'fa fa-plus', 'module.jsp?but=heuredepointe/heuredepointe-saisie.jsp', 2, 3, 'MENUDYN_HDP001');

COMMIT;
