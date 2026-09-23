# Plan de développement du POC

Ce document transforme l'architecture en petits jalons de développement faciles à comprendre, à
tester et à valider.

Le but n'est pas de construire immédiatement un produit prêt pour la production. Le POC doit
seulement démontrer que les principales étapes du provisionnement peuvent fonctionner ensemble :

```text
Source SQL simulée
    → acquisition
    → identité canonique
    → règles PowerShell
    → état désiré
    → comparaison avec le tenant de test
    → plan de changements
    → provisionnement
```

## 1. Règles de développement

- Un jalon doit produire un résultat visible et testable.
- Un jalon doit rester assez petit pour être compris et validé séparément.
- On termine et valide un jalon avant de commencer le suivant.
- Chaque jalon comprend seulement le code nécessaire à sa démonstration.
- Les tests ciblent le comportement principal, pas tous les cas limites possibles.
- On préfère une implémentation simple et remplaçable à une abstraction prématurée.
- La robustesse de production est reportée jusqu'à ce que le POC confirme l'approche.
- Chaque traitement publie des événements simples qui permettent de suivre sa progression.
- Le portail lit un état consolidé; il ne reconstruit pas cet état en parcourant tout le journal.

Dans la mesure du possible, chaque jalon correspond à un petit commit ou à une petite demande de
tirage.

## 2. Ce que le POC ne cherche pas encore à faire

- Haute disponibilité, reprise après sinistre ou déploiement multi-instance.
- Optimisation pour de très grands volumes.
- Gestion complète des secrets.
- Isolation renforcée de PowerShell.
- Interface d'administration complète.
- Gestion avancée des rôles et des permissions.
- Couverture exhaustive des cas limites.
- Prise en charge de plusieurs moteurs SQL ou répertoires cibles.
- Écriture dans un environnement autre que le tenant de test prévu pour le POC.

Ces sujets demeurent importants, mais ils ne doivent pas ralentir la validation technique initiale.

## 3. Jalons

### Jalon 0 — Valider SCIM avec le tenant de test

**Objectif**

Déterminer rapidement si l'approvisionnement entrant piloté par API de Microsoft Entra peut servir
de premier mécanisme de provisionnement du POC.

Ce jalon est un *spike* technique isolé. Il précède la construction de la solution afin d'éviter de
concevoir le connecteur autour d'une approche qui ne répondrait pas au besoin.

**Préalables**

1. Confirmer que le tenant de test possède une licence Entra ID P1, P2 ou Governance.
2. Créer une application « API-driven inbound provisioning to Microsoft Entra ID ».
3. Définir un périmètre contenant uniquement des identités fictives.
4. Autoriser l'appel de `/bulkUpload` et la lecture des journaux de provisionnement.
5. Vérifier si `employeeId` est déjà utilisé et s'il est unique dans le périmètre.
6. Confirmer le mapping entre `externalId` et l'attribut d'ancrage retenu.

**Étapes**

1. Générer avec PowerShell un payload SCIM contenant dix personnes fictives.
2. Vérifier que les dix identifiants externes, noms d'utilisateur et `bulkId` sont uniques.
3. Envoyer le lot de dix opérations à `/bulkUpload`.
4. Conserver l'identifiant de corrélation et la réponse `202 Accepted`.
5. Suivre les opérations dans les Provisioning Logs.
6. Confirmer la création des comptes dans le tenant de test.
7. Modifier une propriété simple et renvoyer les profils complets.
8. Confirmer les modifications dans le tenant.
9. Envoyer les profils avec l'état inactif et confirmer les désactivations.
10. Renvoyer le même état et confirmer qu'aucun doublon n'est créé.
11. Documenter le payload, les mappings, les résultats, les délais et les erreurs rencontrées.

**Validation**

- Le même identifiant externe retrouve toujours le même compte.
- L'attribut d'ancrage ne remplace aucune donnée existante du tenant.
- Le payload contient exactement dix opérations et dix identités uniques.
- La création, la modification et la désactivation fonctionnent.
- Les Provisioning Logs permettent de relier chaque résultat à la requête envoyée.
- Une répétition du même profil ne crée aucun doublon.
- Les erreurs retournées sont assez précises pour alimenter `ActivityEvents`.
- Aucun compte hors du périmètre du test n'est touché.

**Décision de fin de jalon**

- **SCIM retenu** : `/bulkUpload` devient le premier adaptateur de provisionnement du POC.
- **SCIM rejeté** : documenter la raison et utiliser Microsoft Graph directement pour les jalons de
  provisionnement.

**Hors portée**

- Source SQL.
- Azure Functions.
- Blazor.
- Traitement de lots importants.
- Connecteur de production.
- Abstraction commune SCIM/Graph.

---

### Jalon 1 — Démarrer une application minimale

**Objectif**

Créer une solution .NET minimale qui sépare l'interface, les traitements et la logique partagée.

**Étapes**

1. Créer la solution.
2. Ajouter une application Blazor Web App pour l'interface.
3. Ajouter un projet Azure Functions pour l'acquisition et le provisionnement planifiés.
4. Ajouter une bibliothèque partagée pour la logique du POC.
5. Ajouter un projet de tests pour cette logique.
6. Afficher un message indiquant que le POC est prêt dans Blazor.
7. Exécuter une première fonction locale qui confirme que le traitement est prêt.
8. Ajouter un premier test automatisé très simple.

**Structure initiale**

```text
Solution
├── Web          Interface Blazor
├── Functions    Déclencheurs et traitements planifiés
├── Core         Modèles et logique partagée
└── Tests        Tests de la logique partagée
```

**Validation**

- La solution compile.
- Les tests passent.
- L'application Blazor démarre et affiche le message attendu.
- Le projet Azure Functions démarre localement et exécute la fonction de vérification.

**Hors portée**

- API complète.
- Conteneurisation.
- Déploiement dans Azure.
- Communication avancée entre Blazor et Azure Functions.

---

### Jalon 2 — Suivre une première activité

**Objectif**

Valider le mécanisme minimal de suivi utilisé par tous les jalons suivants.

**Étapes**

1. Définir une activité avec un identifiant, un type, un statut et des dates.
2. Créer la table `ActivityEvents` pour le journal immuable.
3. Créer la table `Activities` pour l'état courant consolidé.
4. Ajouter dans Blazor un bouton qui demande le démarrage d'une activité fictive.
5. Faire passer cette demande par une fonction HTTP.
6. Publier un message de travail et exécuter une fonction de traitement.
7. Faire progresser l'activité jusqu'à son état final.
8. Afficher son statut courant et sa chronologie dans Blazor.

**Validation**

- L'activité passe de `Pending` à `Running`, puis à `Succeeded`.
- La table `Activities` contient son dernier état.
- La table `ActivityEvents` conserve les trois événements dans l'ordre.
- Le bouton du portail déclenche le traitement sans exécuter sa logique dans Blazor.
- Un test vérifie la projection du statut courant.

**Hors portée**

- *Event sourcing* complet.
- Service Bus ou Event Hubs.
- Reprise automatique et gestion avancée des messages en erreur.

---

### Jalon 3 — Créer la source SQL simulée

**Objectif**

Disposer d'une petite base SQL locale contenant des identités fictives.

**Étapes**

1. Choisir un moteur SQL local simple pour le POC.
2. Créer une table contenant quelques personnes fictives.
3. Inclure au moins une personne active, une personne modifiée et une personne inactive.
4. Fournir un script reproductible pour créer et remplir la base.
5. Lire les lignes et les afficher sans transformation.

**Validation**

- La base peut être recréée à partir de zéro.
- L'application affiche exactement les enregistrements simulés.
- Un test vérifie la lecture d'au moins une personne.

**Hors portée**

- Schéma métier complet.
- Données réelles.
- Chargement incrémental.
- Découverte automatique de schéma.

---

### Jalon 4 — Définir une identité canonique minimale

**Objectif**

Transformer une ligne SQL en une représentation indépendante de la source.

**Contrat minimal proposé**

- Identifiant de source.
- Prénom.
- Nom.
- Nom d'affichage.
- Type de personne.
- État actif ou inactif.
- Organisation ou établissement.
- Date de dernière modification.

**Étapes**

1. Définir le modèle canonique minimal.
2. Mapper les colonnes SQL vers ce modèle.
3. Afficher le résultat canonique en JSON.
4. Ajouter un test de projection.

**Validation**

- Une ligne SQL produit l'identité canonique attendue.
- La sortie JSON est lisible et stable.
- Le modèle canonique ne contient aucune dépendance au schéma SQL simulé.

**Hors portée**

- Toutes les propriétés métier possibles.
- Affiliations multiples.
- Rapprochement de plusieurs sources.

---

### Jalon 5 — Ajouter une acquisition Bronze avec rejeu simple

**Objectif**

Conserver une copie Bronze des données acquises afin de pouvoir retraiter un lot sans relire la
source.

**Étapes**

1. Démarrer une activité d'acquisition et lui donner un identifiant.
2. Enregistrer les lignes brutes et leur provenance.
3. Permettre de projeter les identités à partir de la copie enregistrée.
4. Ajouter une commande simple pour rejouer une acquisition.
5. Publier les événements de progression et le statut final.

**Validation**

- Une acquisition peut être consultée après sa lecture.
- La source SQL peut être rendue indisponible et le rejeu fonctionne toujours.
- Un test confirme que le rejeu produit le même résultat canonique.

**Hors portée**

- Nettoyage automatique de l'historique.
- Reprise distribuée.
- Parallélisation.

---

### Jalon 6 — Appliquer une règle PowerShell simple

**Objectif**

Démontrer qu'une règle PowerShell peut transformer une identité canonique en état désiré.

**Exemple de règle**

Construire un nom d'utilisateur et une adresse courriel à partir du prénom et du nom.

**Étapes**

1. Définir un petit contrat JSON d'entrée et de sortie.
2. Fournir un script PowerShell d'exemple.
3. Exécuter le script pour une identité.
4. Valider la sortie avant de l'accepter.
5. Ajouter un test avec une entrée et une sortie connues.

**Validation**

- Le script reçoit l'identité canonique attendue.
- Il retourne un état désiré valide.
- Une erreur de script est affichée clairement.

**Hors portée**

- Éditeur de scripts.
- Versionnement dans un portail.
- Bac à sable de sécurité complet.
- Limites avancées de mémoire et de durée.

---

### Jalon 7 — Comparer avec une destination simulée

**Objectif**

Produire un plan de changements sans contacter un répertoire réel.

**Étapes**

1. Créer quelques comptes de destination fictifs.
2. Comparer l'état désiré à l'état observé.
3. Produire trois types de changements : créer, modifier et désactiver.
4. Afficher les changements sans les appliquer.
5. Ajouter un test pour chaque type de changement.

**Validation**

- Une identité absente produit une création.
- Une propriété différente produit une modification.
- Une identité inactive produit une désactivation.
- Relancer la comparaison avec deux états identiques ne produit aucun changement.

**Hors portée**

- Écriture réelle.
- Gestion de conflits complexes.
- Seuils de sécurité configurables.

---

### Jalon 8 — Réaliser le premier parcours complet

**Objectif**

Relier les composants développés dans un seul scénario exécutable.

**Étapes**

1. Ajouter une fonction qui déclenche manuellement le parcours.
2. Créer l'activité et publier le premier message de travail.
3. Lire la source SQL simulée et enregistrer l'acquisition Bronze.
4. Produire les identités canoniques Argent.
5. Exécuter les règles PowerShell et produire les états désirés Or.
6. Comparer le résultat à la destination simulée.
7. Générer un rapport de prévisualisation.
8. Publier les événements de progression et le statut final.
9. Ajouter ensuite un déclencheur planifié simple qui appelle le même parcours.

**Validation**

- Une seule fonction exécute tout le parcours.
- Le déclenchement manuel et le déclenchement planifié utilisent la même logique partagée.
- L'activité permet de suivre l'étape courante et la chronologie complète.
- Le rapport explique la provenance de chaque changement.
- Les mêmes données produisent le même plan.
- Un test d'intégration couvre le parcours complet.

**Hors portée**

- Planification automatique.
- Interface graphique.
- Exécution concurrente.

---

### Jalon 9 — Lire le tenant de test en mode lecture seule

**Objectif**

Remplacer la destination simulée par la lecture d'un petit périmètre dans le tenant de test
Microsoft Entra ID.

**Étapes**

1. Configurer une application avec les permissions minimales de lecture.
2. Lire un ensemble très limité de comptes de test.
3. Convertir les comptes lus en état observé.
4. Générer le plan de changements sans aucune écriture.
5. Masquer les données sensibles dans les sorties et les tests.

**Validation**

- Le POC lit uniquement le périmètre prévu.
- Aucune permission d'écriture n'est accordée.
- Le plan distingue correctement les créations et les modifications potentielles.
- Les résultats peuvent être comparés manuellement avec le portail Entra.

**Hors portée**

- Application des changements.
- Gestion complète des limites de débit.
- Synchronisation de toute une organisation.

---

### Jalon 10 — Afficher la prévisualisation dans Blazor

**Objectif**

Permettre de consulter facilement dans l'application Blazor le résultat produit par Azure
Functions.

**Étapes**

1. Rendre le dernier rapport accessible à l'application Blazor.
2. Afficher les créations, modifications et désactivations séparément.
3. Afficher la valeur actuelle et la valeur désirée.
4. Permettre de télécharger le rapport en JSON.
5. Ajouter un bouton pour déclencher une nouvelle acquisition et la génération d'un plan.
6. Afficher l'activité créée et rafraîchir son statut jusqu'à la fin du traitement.

**Validation**

- Le rapport peut être consulté sans lire les journaux techniques.
- Chaque changement est compréhensible par une personne qui valide le POC.
- Aucun bouton d'application réelle n'est encore présent.
- L'interface ne contient pas la logique de provisionnement; elle affiche le résultat produit par
  Azure Functions.
- Une opération déclenchée dans le portail suit le même parcours qu'une exécution planifiée.

**Hors portée**

- Design visuel final.
- Authentification et autorisation complètes.
- Historique avancé et recherche.

---

### Jalon 11 — Créer un premier compte dans le tenant de test

**Objectif**

Valider le premier provisionnement réel en créant un seul compte dans le tenant de test.

**Étapes**

1. Ajouter un seul utilisateur fictif dans la source SQL.
2. Générer et vérifier son plan de création.
3. Confirmer explicitement l'application du plan.
4. Créer le compte dans le tenant de test.
5. Relire le compte créé et comparer ses propriétés à l'état désiré.
6. Exécuter le même parcours une deuxième fois.

**Validation**

- Un seul compte est créé.
- Les propriétés relues correspondent aux valeurs désirées.
- La deuxième exécution ne crée aucun doublon et ne propose aucun changement.

**Hors portée**

- Création en lot.
- Modification et désactivation.
- Écriture dans un autre tenant.

---

### Jalon 12 — Modifier un compte provisionné

**Objectif**

Valider qu'une modification provenant de la source SQL est appliquée au bon compte dans le tenant
de test.

**Étapes**

1. Modifier une propriété simple dans la source SQL simulée.
2. Générer un plan contenant une seule modification.
3. Confirmer et appliquer le plan.
4. Relire le compte dans Entra ID.
5. Exécuter le parcours une deuxième fois.

**Validation**

- Seul le compte attendu est modifié.
- Seule la propriété prévue change.
- La valeur relue correspond à l'état désiré.
- La deuxième exécution ne propose aucun changement.

**Hors portée**

- Modifications en lot.
- Gestion de conflits complexes.
- Changement de propriétés sensibles.

---

### Jalon 13 — Désactiver un compte provisionné

**Objectif**

Valider le cycle de vie minimal en désactivant un compte marqué inactif dans la source SQL.

**Étapes**

1. Marquer le compte fictif comme inactif dans la source SQL.
2. Générer un plan contenant une seule désactivation.
3. Confirmer et appliquer le plan.
4. Relire le compte dans Entra ID.
5. Vérifier qu'aucune suppression n'a eu lieu.

**Validation**

- Le compte attendu est désactivé.
- Aucun autre compte n'est touché.
- Le compte existe toujours dans le tenant de test.
- Une deuxième exécution ne propose aucun changement.

**Hors portée**

- Suppression définitive.
- Désactivation en masse.
- Périodes de grâce et réactivation automatique.

---

### Jalon 14 — Provisionner un petit lot de bout en bout

**Objectif**

Valider le parcours complet avec un petit ensemble d'identités fictives dans le tenant de test.

**Étapes**

1. Préparer un jeu de données comprenant quelques créations, une modification et une désactivation.
2. Exécuter le parcours complet depuis la source SQL.
3. Examiner et confirmer le plan de changements.
4. Appliquer le plan au tenant de test.
5. Relire les comptes et produire le rapport final.
6. Réexécuter le parcours sans modifier la source.

**Validation**

- Chaque identité produit l'action attendue.
- Aucun compte hors du périmètre du POC n'est touché.
- Le rapport final correspond à l'état réellement observé.
- La deuxième exécution produit un plan vide.

**Hors portée**

- Population complète.
- Exécution planifiée sans supervision.
- Utilisation dans un tenant de production.

## 4. Critère de succès du POC

Le POC est concluant si les jalons démontrent que :

1. une source SQL peut être acquise et rejouée;
2. ses données peuvent être projetées vers un modèle canonique;
3. des règles PowerShell peuvent produire un état désiré;
4. cet état peut être comparé à une destination simulée puis au tenant de test;
5. un plan de changements compréhensible et reproductible peut être produit;
6. des comptes peuvent être créés, modifiés et désactivés de façon idempotente dans le tenant de
   test;
7. l'approche fournit assez d'information pour estimer la suite du projet.

## 5. Méthode de validation

À la fin de chaque jalon :

1. présenter les fichiers ajoutés ou modifiés;
2. expliquer le parcours en quelques phrases;
3. exécuter uniquement les tests liés au jalon;
4. fournir une commande ou une procédure de validation manuelle;
5. attendre l'acceptation du jalon avant de poursuivre.
