/*Let’s implemente a Cypher query that answers the question "How many reviews does each Matrix
movie have?". Don’t worry if this seems complex, we’ll build up our understanding of Cypher as we
move along.
Int: Replace ??? by the corrects values*/

MATCH (m :Movie) <- [ :RATED]-(u :User)
WHERE m.title CONTAINS 'Matrix'
WITH m, COUNT(*) AS reviews
RETURN m.title AS movie, reviews
ORDER BY reviews DESC LIMIT 5;

//Content-Based Filtering : 1/ "Find Items similar to the item you’re looking at now"
MATCH p=(m:Movie {title: 'Net, The'})-[:ACTED_IN|IN_GENRE|DIRECTED*2]-()
RETURN p LIMIT 25;

//Collaborative Filtering : 1/ " Get Users who got this item, also got that other item."
MATCH (m:Movie {title: 'Crimson Tide'})<-[:RATED]- (u:User)-[:RATED]->(rec:Movie)
WITH rec, COUNT(*) AS usersWhoAlsoWatched
ORDER BY usersWhoAlsoWatched DESC LIMIT 25
RETURN rec.title AS recommendation, usersWhoAlsoWatched

//Similarity Based on Common Genres : 1/ Find movies most similar to Inception based on shared genres
MATCH (m:Movie)-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(rec:Movie)
WHERE m.title = 'Inception'
WITH rec, collect(g.name) AS genres, COUNT(*) AS commonGenres
RETURN rec.title, genres, commonGenres

//Personalized Recommendations Based on Genres : 1/ Recommend movies similar to those the user has already watched
MATCH (u:User {name: 'Angelica Rodriguez'})-[r:RATED]->(m:Movie),(m)-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(rec:Movie)
WHERE NOT exists{ (u)-[:RATED]->(rec) }
WITH rec, g.name AS genre, COUNT(*) AS count
WITH rec, collect([genre, count]) AS scoreComponents
RETURN rec.title AS recommendation, rec.year AS year, scoreComponents,reduce(s=0,x IN scoreComponents | s+x[1]) AS score
ORDER BY score DESC LIMIT 10;


//Weighted Content Algorithm: Compute a weighted sum based on the number and types of overlapping traits
MATCH (m:Movie) WHERE m.title = 'Wizard of Oz, The'
MATCH (m)-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(rec:Movie)
WITH m, rec, COUNT(*) AS gs
OPTIONAL MATCH (m)<-[:ACTED_IN]-(a)-[:ACTED_IN]->(rec)
WITH m, rec, gs, count(a) AS as
OPTIONAL MATCH (m)<-[:DIRECTED]-(d)-[:DIRECTED]->(rec)
WITH m, rec, gs, as, count(d) AS ds
RETURN rec.title AS recommendation,(5*gs)+(3*as)+(4*ds) AS score
ORDER BY score DESC LIMIT 25

//Jaccard Index : What movies are most similar to Inception based on Jaccard similarity of genres?
MATCH (m:Movie {title:'Inception'})-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(other:Movie)
WITH m, other, count(g) AS intersection, collect(g.name) AS common
WITH m,other, intersection, common,[(m)-[:IN_GENRE]->(mg) | mg.name] AS set1,[(other)-[:IN_GENRE]->(og) | og.name] AS set2
WITH m,other,intersection, common, set1, set2,set1+[x IN set2 WHERE NOT x IN set1] AS union
RETURN m.title, other.title, common, set1,set2,((1.0*intersection)/size(union)) AS jaccard
ORDER BY jaccard DESC LIMIT 25;

//Apply this same approach to all "traits" of the movie (genre, actors, directors, etc.):
MATCH (m:Movie {title: 'Inception'})-[:IN_GENRE|ACTED_IN|DIRECTED]-(t)<-[:IN_GENRE|ACTED_IN|DIRECTED]-(other:Movie)
WITH m, other, count(t) AS intersection, collect(t.name) AS common,[(m)-[:IN_GENRE|ACTED_IN|DIRECTED]-(mt) | mt.name] AS set1, [(other)-[:IN_GENRE|ACTED_IN|DIRECTED]-(ot) | ot.name] AS set2
WITH m,other,intersection, common, set1, set2,set1 + [x IN set2 WHERE NOT x IN set1] AS union
RETURN m.title, other.title, common, set1,set2,((1.0*intersection)/size(union)) AS jaccard
ORDER BY jaccard DESC LIMIT 25

//Collaborative Filtering – Leveraging Movie Ratings: 1. Find similar users in the network (our peer group).
//2. Assuming that similar users have similar preferences, what are the movies those similar users like?

//Show all ratings by Misty Williams
MATCH (u:User {name: 'Misty Williams'})
MATCH (u)-[r:RATED]->(m:Movie)
RETURN *
LIMIT 100;

//Find Misty’s average rating
MATCH (u:User {name: 'Misty Williams'})
MATCH (u)-[r:RATED]->(m:Movie)
RETURN avg(r.rating) AS average;

//What are the movies that Misty liked more than average?
MATCH (u:User {name: 'Misty Williams'})
MATCH (u)-[r:RATED]->(m:Movie)
WITH u, avg(r.rating) AS average
MATCH (u)-[r:RATED]->(m:Movie)
WHERE r.rating > average
RETURN *
LIMIT 100;

//Only Consider Genres Liked by the User
//For a particular user, what genres have a higher-than-average rating? Use this to score similar movies
MATCH (u:User {name: 'Cynthia Freeman'})-[:RATED]-> (:Movie)<-[:RATED]-(peer:User)
MATCH (peer)-[:RATED]->(rec:Movie)
WHERE NOT exists { (u)-[:RATED]->(rec) }
RETURN rec.title, rec.year, rec.plot LIMIT 25;

//Cosine Similarity
//Find the users with the most similar preferences to Cynthia Freeman, according to cosine similarity
MATCH (u:User {name: 'Cynthia Freeman'})-[r1:RATED]-> (:Movie)<-[r2:RATED]-(peer:User)
WHERE abs(r1.rating-r2.rating) < 2 // similarly rated WITH distinct u, peer
MATCH (peer)-[r3:RATED]->(rec:Movie) WHERE r3.rating > 3
AND NOT exists { (u)-[:RATED]->(rec) }
WITH rec, COUNT(*) AS freq, avg(r3.rating) AS rating RETURN rec.title, rec.year, rating, freq, rec.plot ORDER BY rating DESC, freq DESC
LIMIT 25;

//Find the users with the most similar preferences to Cynthia Freeman, according to cosine similarity function
MATCH (u:User {name: 'Andrew Freeman'})-[r:RATED]->(m:Movie)
WITH u, avg(r.rating) AS mean
MATCH (u)-[r:RATED]->(m:Movie)-[:IN_GENRE]->(g:Genre)
WHERE r.rating > mean
WITH u, g, COUNT(*) AS score
MATCH (g)<-[:IN_GENRE]-(rec:Movie)
WHERE NOT exists { (u)-[:RATED]->(rec) }
RETURN rec.title AS recommendation, rec.year AS year, sum(score) AS scor, collect(DISTINCT g.name) AS genres
ORDER BY scor DESC LIMIT 10;

//Collaborative Filtering – Similarity Metrics Pearson Similarity
//Find users most similar to Cynthia Freeman, according to Pearson similarity
MATCH (u1:User {name: 'Cynthia Freeman'})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WITH u1, u2, count(m) AS numbermovies, sum(r1.rating * r2.rating) AS r1r2DotProduct, collect(r1.rating) AS r1Ratings, collect(r2.rating) AS r2RatingsWHERE numbermovies > 10
WITH u1, u2, r1r2DotProduct, sqrt(reduce(r1Dot = 0.0, a IN r1Ratings | r1Dot + a^2))
AS r1Length, sqrt(reduce(r2Dot = 0.0, b IN r2Ratings | r2Dot + b^2)) AS r2Length
RETURN u1.name, u2.name, r1r2DotProduct / (r1Length * r2Length) AS sim
ORDER BY sim DESC
LIMIT 100;

//Find users most similar to Cynthia Freeman, according to the Pearson similarity function
MATCH (u1:User {name: 'Cynthia Freeman'})-[r1:RATED]->(movie)<-[r2:RATED]-(u2:User)
WHERE u2 <> u1
WITH u1, u2, collect(r1.rating) AS u1Ratings, collect(r2.rating) AS u2Ratings
WHERE size(u1Ratings) > 10
RETURN u1.name AS from, u2.name AS to, gds.similarity.cosine(u1Ratings, u2Ratings) AS  similarity
ORDER BY similarity DESC

//kNN – K-Nearest Neighbors
//kNN movie recommendation using Pearson similarity
MATCH (u1:User {name:'Cynthia Freeman'})-[r:RATED]->(m:Movie)
WITH u1, avg(r.rating) AS u1_mean
MATCH (u1)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2)
WITH u1, u1_mean, u2, collect({r1: r1, r2: r2}) AS ratings WHERE size(ratings) > 10
MATCH (u2)-[r:RATED]->(m:Movie)
WITH u1, u1_mean, u2, avg(r.rating) AS u2_mean, ratings
UNWIND ratings AS r
WITH sum( (r.r1.rating-u1_mean) * (r.r2.rating-u2_mean) ) AS nom, sqrt( sum( (r.r1.rating - u1_mean)^2) * sum( (r.r2.rating - u2_mean) ^2)) AS denom,
u1, u2 WHERE denom <> 0
WITH u1, u2, nom/denom AS pearson
ORDER BY pearson DESC LIMIT 10
MATCH (u2)-[r:RATED]->(m:Movie) WHERE NOT exists( (u1)-[:RATED]->(m) )
RETURN m.title, sum( pearson * r.rating) AS score
ORDER BY score DESC LIMIT 25


//Further Work
//Temporal component
MATCH (u:User {name: 'Alice'}), (m:Movie {title: 'Inception'})
CREATE (u)-[r:RATED {rating: 5, timestamp: timestamp()}]->(m)

//Keyword extraction
//Ajout de Timestamp aux Évaluations
MATCH (m:Film)
WHERE exists(m.plotDescription)
WITH m, apoc.text.extractKeywords(m.plotDescription) AS keywords
FOREACH (keyword IN keywords | MERGE (k:MotCle {nom: keyword})-[:ASSOCIE]->(m))

//Recommandations Basées sur les Évaluations Récentes
MATCH (u:User {name: 'Alice'})-[r:RATED]->(m:Movie)<-[:ACTED_IN]-(a:Actor)-[:ACTED_IN]->(rec:Movie)
WHERE r.timestamp > timestamp() - 604800000 // Les 7 derniers jours
AND NOT (u)-[:RATED]->(rec)
RETURN rec.title, count(a) AS commonActors, avg(r.rating) AS avgRating
ORDER BY avgRating DESC, commonActors DESC
LIMIT 5

//Utilisation des Périodes pour Pondérer les Évaluations
MATCH (u:User {name: 'Alice'})-[r:RATED]->(m:Movie)<-[:ACTED_IN]-(a:Actor)-[:ACTED_IN]->(rec:Movie)
WHERE NOT (u)-[:RATED]->(rec)
WITH rec, r.rating, r.timestamp, (timestamp() - r.timestamp) AS age
RETURN rec.title, sum(r.rating / age) AS weightedRating
ORDER BY weightedRating DESC
LIMIT 5

//Filtrage Basé sur une Période Spécifique
MATCH (u:User {name: 'Alice'})-[r:RATED]->(m:Movie)
WHERE r.timestamp > timestamp() - 2592000000 // Les 30 derniers jours
RETURN m.title, r.rating, r.timestamp
ORDER BY r.timestamp DESC

//Créons une relation HAS_KEYWORD entre les nœuds Movie et les nœuds Keyword
// Supposons que nous avons les mots-clés extraits sous forme de liste
WITH ['science fiction', 'dream invasion', 'manipulation'] AS keywords
MATCH (m:Movie {title: 'Inception'})
UNWIND keywords AS keyword
MERGE (k:Keyword {name: keyword})
MERGE (m)-[:HAS_KEYWORD]->(k)

//Requêtes pour Utiliser les Mots-Clés Rechercher des Films par Mots-Clés :
MATCH (m:Movie)-[:HAS_KEYWORD]->(k:Keyword)
WHERE k.name IN ['science fiction', 'manipulation']
RETURN m.title, collect(k.name) AS keywords

//Recommander des Films Basés sur des Mots-Clés Similaires :
MATCH (u:User {name: 'Alice'})-[:RATED]->(m:Movie)-[:HAS_KEYWORD]->(k:Keyword)<-[:HAS_KEYWORD]-(rec:Movie)
WHERE NOT (u)-[:RATED]->(rec)
RETURN rec.title, count(k) AS commonKeywords
ORDER BY commonKeywords DESC
LIMIT 5

//Gestion et Mise à Jour des Mots-Clés
MATCH (m:Movie {title: 'Inception'})-[r:HAS_KEYWORD]->(k:Keyword)
DELETE r
WITH m
// Ajouter les nouveaux mots-clés après suppression des anciens
WITH ['nouveau mot-clé 1', 'nouveau mot-clé 2'] AS newKeywords, m
UNWIND newKeywords AS newKeyword
MERGE (k:Keyword {name: newKeyword})
MERGE (m)-[:HAS_KEYWORD]->(k)

//Ajoutons des Mots-Clés Extraits comme Nœuds et Relations Supposons qu’on a extrait des motsclés tels que "science fiction", "action", et "thriller" pour un film. On peut les ajouter à Neo4j
//comme suit :
// Créer un nœud pour le film
MERGE (m:Movie {title: 'Inception'})
// Créer des nœuds pour les mots-clés et les relier au film
WITH ['science fiction', 'action', 'thriller'] AS keywords, m
UNWIND keywords AS keyword
MERGE (k:Keyword {name: keyword})
MERGE (m)-[:HAS_KEYWORD]->(k)

//Exemple de Requête pour Trouver des Films par Mots-Clés :
MATCH (m:Movie)-[:HAS_KEYWORD]->(k:Keyword)
WHERE k.name IN ['science fiction', 'action']
RETURN m.title, COLLECT(k.name) AS keywords