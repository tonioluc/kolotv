-- ============================================
-- Script SQL pour la gestion des heures de pointe de majoration
-- Date: 2026-02-05
-- Description: Ajoute la fonctionnalité d'heure de pointe avec majoration
--              sur les prix de diffusion (chevauchement ou non)
--              La majoration peut être configurée pour un jour de la semaine spécifique
-- ============================================

-- Création de la séquence pour les ID
CREATE SEQUENCE SEQ_HEUREPOINTE
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Fonction pour générer l'ID
CREATE OR REPLACE FUNCTION GETSEQ_HEUREPOINTE RETURN VARCHAR2 IS
  seq_val NUMBER;
BEGIN
  SELECT SEQ_HEUREPOINTE.NEXTVAL INTO seq_val FROM DUAL;
  RETURN seq_val;
END;
/

-- Création de la table HEUREPOINTE
CREATE TABLE HEUREPOINTE (
    ID VARCHAR2(50) PRIMARY KEY,
    HEUREDEBUT VARCHAR2(10) NOT NULL,           -- Format HH:mm:ss
    HEUREFIN VARCHAR2(10) NOT NULL,             -- Format HH:mm:ss
    POURCENTAGEMAJORATION NUMBER(10,2) DEFAULT 0, -- Pourcentage de majoration (ex: 10 pour 10%)
    DESIGNATION VARCHAR2(255),                   -- Description de l'heure de pointe
    ETAT NUMBER(2) DEFAULT 1,                    -- Etat (1=créé, 11=validé, 0=annulé)
    IDSUPPORT VARCHAR2(50),                      -- Support concerné (NULL = tous les supports)
    JOURSEMAINE NUMBER(1) DEFAULT 0,             -- Jour de la semaine (0=Tous, 1=Lundi, 2=Mardi, 3=Mercredi, 4=Jeudi, 5=Vendredi, 6=Samedi, 7=Dimanche)
    CONSTRAINT FK_HEUREPOINTE_SUPPORT FOREIGN KEY (IDSUPPORT) REFERENCES SUPPORT(ID),
    CONSTRAINT CHK_JOURSEMAINE CHECK (JOURSEMAINE >= 0 AND JOURSEMAINE <= 7)
);

-- Création de la vue complémentaire HEUREPOINTE_CPL
CREATE OR REPLACE VIEW HEUREPOINTE_CPL AS
SELECT 
    hp.ID,
    hp.HEUREDEBUT,
    hp.HEUREFIN,
    hp.POURCENTAGEMAJORATION,
    hp.DESIGNATION,
    hp.ETAT,
    hp.IDSUPPORT,
    hp.JOURSEMAINE,
    s.VAL AS IDSUPPORTLIB,
    CASE
        WHEN hp.ETAT = 0 THEN 'ANNULEE'
        WHEN hp.ETAT = 1 THEN 'CREE'
        WHEN hp.ETAT = 11 THEN 'VALIDEE'
    END AS ETATLIB,
    CASE hp.JOURSEMAINE
        WHEN 0 THEN 'Tous les jours'
        WHEN 1 THEN 'Lundi'
        WHEN 2 THEN 'Mardi'
        WHEN 3 THEN 'Mercredi'
        WHEN 4 THEN 'Jeudi'
        WHEN 5 THEN 'Vendredi'
        WHEN 6 THEN 'Samedi'
        WHEN 7 THEN 'Dimanche'
    END AS JOURSEMAINELIB
FROM HEUREPOINTE hp
LEFT JOIN SUPPORT s ON s.ID = hp.IDSUPPORT;

-- Index pour améliorer les performances de recherche
CREATE INDEX IDX_HEUREPOINTE_ETAT ON HEUREPOINTE(ETAT);
CREATE INDEX IDX_HEUREPOINTE_SUPPORT ON HEUREPOINTE(IDSUPPORT);
CREATE INDEX IDX_HEUREPOINTE_HEURES ON HEUREPOINTE(HEUREDEBUT, HEUREFIN);
CREATE INDEX IDX_HEUREPOINTE_JOUR ON HEUREPOINTE(JOURSEMAINE);

-- Insertion d'exemples d'heures de pointe (optionnel)
-- Exemple: Heure de pointe du matin de 9h à 11h avec majoration de 10% - uniquement le LUNDI
INSERT INTO HEUREPOINTE (ID, HEUREDEBUT, HEUREFIN, POURCENTAGEMAJORATION, DESIGNATION, ETAT, IDSUPPORT, JOURSEMAINE)
VALUES ('HPT001', '09:00:00', '11:00:00', 10, 'Heure de pointe du matin - vendredi', 11, NULL, 5);

-- Exemple: Heure de pointe du soir de 18h à 20h avec majoration de 15% - tous les jours
INSERT INTO HEUREPOINTE (ID, HEUREDEBUT, HEUREFIN, POURCENTAGEMAJORATION, DESIGNATION, ETAT, IDSUPPORT, JOURSEMAINE)
VALUES ('HPT002', '18:00:00', '20:00:00', 15, 'Heure de pointe du soir', 11, NULL, 0);

-- Exemple: Heure de pointe du weekend - Samedi et Dimanche (2 entrées distinctes)
INSERT INTO HEUREPOINTE (ID, HEUREDEBUT, HEUREFIN, POURCENTAGEMAJORATION, DESIGNATION, ETAT, IDSUPPORT, JOURSEMAINE)
VALUES ('HPT003', '12:00:00', '14:00:00', 20, 'Heure de pointe midi - Samedi', 11, NULL, 6);

INSERT INTO HEUREPOINTE (ID, HEUREDEBUT, HEUREFIN, POURCENTAGEMAJORATION, DESIGNATION, ETAT, IDSUPPORT, JOURSEMAINE)
VALUES ('HPT004', '12:00:00', '14:00:00', 20, 'Heure de pointe midi - Dimanche', 11, NULL, 7);

COMMIT;

-- ============================================
-- Insertion des menus pour la gestion des heures de pointe
-- ============================================

-- Menu parent "Heure de Pointe" sous le menu parent MNDT150500134008 (niveau 3)
-- Note: MNDT150500134008 est de niveau 2, donc ses enfants sont de niveau 3
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE) VALUES
    ('MNDN_HP_001', 'Heure de Pointe', 'fa fa-clock-o', NULL, 10, 3, 'MNDT150500134008');

-- Sous-menu Liste (niveau 4)
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE) VALUES
    ('MNDN_HP_002', 'Liste', 'fa fa-list', 'module.jsp?but=heurepointe/heurepointe-liste.jsp', 1, 4, 'MNDN_HP_001');

-- Sous-menu Saisie (niveau 4)
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE) VALUES
    ('MNDN_HP_003', 'Nouvelle Heure de Pointe', 'fa fa-plus', 'module.jsp?but=heurepointe/heurepointe-saisie.jsp', 2, 4, 'MNDN_HP_001');

COMMIT;

-- ============================================
-- Vérification de la création
-- ============================================
-- SELECT * FROM HEUREPOINTE;
-- SELECT * FROM HEUREPOINTE_CPL;
-- SELECT * FROM MENUDYNAMIQUE WHERE ID LIKE 'MNDN_HP%';
select * FROM MENUDYNAMIQUE WHERE ID IN ('MNDN_HP_001', 'MNDN_HP_002', 'MNDN_HP_003');
COMMIT;