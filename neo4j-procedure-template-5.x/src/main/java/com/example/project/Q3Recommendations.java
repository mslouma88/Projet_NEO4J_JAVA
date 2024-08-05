package com.example.project;


import org.neo4j.graphdb.*;
import org.neo4j.procedure.*;

import java.util.stream.Stream;

public class Q3Recommendations {

    @Context
    public GraphDatabaseService db;

    public static class Recommendation {
        public String recommendation;
        public long usersWhoAlsoWatched;

        public Recommendation(String recommendation, long usersWhoAlsoWatched) {
            this.recommendation = recommendation;
            this.usersWhoAlsoWatched = usersWhoAlsoWatched;
        }
    }

    @Procedure(name = "recommend.recommendations", mode = Mode.READ)
    @Description("RETURN movie recommendations for users who watched 'Crimson Tide'")
    public Stream<Recommendation> recommendations() {
        try (Transaction tx = db.beginTx()) {
            String query = "MATCH (m:Movie {title: 'Crimson Tide'})<-[:RATED]-(u:User)-[:RATED]->(rec:Movie) " +
                    "WITH rec, COUNT(*) AS usersWhoAlsoWatched " +
                    "ORDER BY usersWhoAlsoWatched DESC LIMIT 25 " +
                    "RETURN rec.title AS recommendation, usersWhoAlsoWatched";
            Result result = tx.execute(query);

            return result.stream().map(row -> new Recommendation((String) row.get("recommendation"), (Long) row.get("usersWhoAlsoWatched"))).onClose(tx::close);
        }
    }
}

