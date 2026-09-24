# Plan des écarts de cybersécurité

Référence :
[Référentiel du Centre gouvernemental de cyberdéfense](https://www.cyber.gouv.qc.ca/publications/referentiel/referentiel-complete.pdf).
Dernière mise à jour : 2026-09-24.

Statuts : **À faire** · **Documenté** (cible décrite, non vérifiée) · **En cours** · **Vérifié** ·
**Écart accepté** · **Non applicable**.

| ID | À faire | Statut | Évidence actuelle | Écart restant | Cible | Responsable |
|---|---|---|---|---|---|---|
| CYB-01 | Identifier les mesures du référentiel applicables au produit | À faire | Aucune | Produire et faire approuver la matrice d'applicabilité; justifier les exclusions | Pilote | Sécurité et conformité |
| CYB-02 | Formaliser l'analyse des risques du produit | Documenté | [Risques et mitigations](./plan-de-travail.md#6-risques-et-pistes-de-mitigation) | Ajouter propriétaire, impact, probabilité, traitement, risque résiduel et date de revue | Pilote | Produit / Sécurité |
| CYB-03 | Inventorier et classifier les données | À faire | [Couches de données](./architecture.md#41-couches-de-données-inspirées-du-modèle-médaillon) | Classifier les données brutes, canoniques, désirées, observées, les journaux et les sauvegardes; préciser confidentialité, intégrité, disponibilité et résidence | Pilote | Responsable des données |
| CYB-04 | Garantir que le POC utilise uniquement des identités fictives dans un tenant isolé | Documenté | [Jalon 0](./plan-developpement-poc.md#jalon-0--valider-bulkupload-avec-le-tenant-de-test) | Vérifier la configuration du tenant et ajouter un contrôle empêchant l'utilisation de données réelles | POC | Produit / Exploitation |
| CYB-05 | Définir les permissions minimales de chaque identité applicative et connecteur | Documenté | [Exigences non fonctionnelles](./architecture.md#15-exigences-non-fonctionnelles) | Produire l'inventaire des permissions et tester le refus d'une opération non autorisée | POC | Sécurité / Développement |
| CYB-06 | Définir les rôles administratifs et séparer les fonctions sensibles | À faire | [Plan de contrôle transversal](./architecture.md#10-plan-de-contrôle-transversal) | Définir qui peut configurer, approuver, publier un script et appliquer un changement; tester chaque rôle | Pilote | Produit / Sécurité |
| CYB-07 | Centraliser, protéger, révoquer et faire tourner les secrets | Documenté | [Exigences non fonctionnelles](./architecture.md#15-exigences-non-fonctionnelles) | Choisir le coffre; configurer ses accès; documenter et tester rotation et révocation | Pilote | Exploitation / Sécurité |
| CYB-08 | Isoler l'exécution PowerShell | Documenté | [Sécurité d'exécution](./architecture.md#72-sécurité-dexécution) | Implanter et tester liste blanche, limites de ressources, absence de secrets et tentatives de contournement | Pilote | Développement / Sécurité |
| CYB-09 | Prévisualiser et approuver les changements à risque avant application | Documenté | [Objectifs et principes directeurs](./architecture.md#2-objectifs-et-principes-directeurs) | Définir les changements soumis à approbation; conserver la décision; tester le refus sans approbation | POC | Produit / Développement |
| CYB-10 | Bloquer les désactivations, suppressions et réinitialisations en volume anormal | Documenté | [Synchronisation complète](./architecture.md#83-synchronisation-complète-comme-filet-de-sécurité) | Définir les seuils configurables et tester l'arrêt automatique ainsi que la reprise approuvée | POC | Développement / Produit |
| CYB-11 | Tracer chaque changement de la source jusqu'à la destination | Documenté | [Activités et événements](./architecture.md#42-activités-et-événements) | Tester la traçabilité complète d'une création, d'une modification et d'une désactivation | POC | Développement |
| CYB-12 | Journaliser les opérations et accès sans exposer de secrets ou de données inutiles | Documenté | [Plan de contrôle transversal](./architecture.md#10-plan-de-contrôle-transversal) | Définir le catalogue d'événements, le masquage, les accès et la conservation; ajouter les tests | Pilote | Développement / Sécurité |
| CYB-13 | Surveiller les erreurs, anomalies, dépassements de seuil et actions administratives sensibles | Documenté | [Plan de contrôle transversal](./architecture.md#10-plan-de-contrôle-transversal) | Définir métriques, alertes, destinataires et délais; déclencher chaque alerte en test | Pilote | Exploitation / Sécurité |
| CYB-14 | Préparer la réponse aux incidents de provisionnement | À faire | Aucune | Documenter et tester l'arrêt des écritures, la révocation des accès, l'analyse et la reprise contrôlée | Pilote | Sécurité / Exploitation |
| CYB-15 | Sauvegarder et restaurer les éléments nécessaires à la reprise | À faire | [Sujets à approfondir](./architecture.md#16-sujets-identifiés-à-approfondir) | Définir RPO/RTO et sauvegarder configurations, métadonnées, scripts, secrets et données; réussir un test de restauration | Production | Exploitation |
| CYB-16 | Détecter et corriger les vulnérabilités des dépendances et environnements | À faire | Aucune | Ajouter les analyses; définir les délais de correction; conserver les rapports et décisions | Pilote | Développement / Sécurité |
| CYB-17 | Protéger l'intégration du code | À faire | Aucune | Exiger revue, protection de branche, compilation, tests et analyses avant intégration | Pilote | Développement |
| CYB-18 | Définir la conservation et la suppression des données et journaux | Documenté | [Exigences non fonctionnelles](./architecture.md#15-exigences-non-fonctionnelles) | Fixer une durée et une méthode de suppression par catégorie; tester la suppression réelle | Production | Données / Conformité |
| CYB-19 | Évaluer chaque fournisseur et modèle d'hébergement | À faire | [Modèle de déploiement](./architecture.md#3-modèle-de-déploiement) | Documenter responsabilités partagées, résidence des données, dépendances critiques et conditions de sortie | Production | Architecture / Sécurité |
| CYB-20 | Bloquer le passage au pilote ou à la production si un écart exigible demeure ouvert | Documenté | [Critères de sortie](./plan-de-travail.md#5-critères-de-sortie-par-étape) | Ajouter une revue formelle de ce tableau aux critères de sortie et consigner chaque décision | POC | Produit / Sécurité |

Un statut **Vérifié** doit pointer vers une preuve consultable. Un statut **Écart accepté** doit
indiquer le propriétaire du risque, les mesures compensatoires, l'autorité d'approbation et la date
d'expiration.
