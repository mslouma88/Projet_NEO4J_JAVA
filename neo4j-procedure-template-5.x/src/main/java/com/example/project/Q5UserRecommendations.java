package com.example.project;


import org.neo4j.graphdb.*;
import org.neo4j.procedure.*;

import java.util.List;
import java.util.stream.Stream;

public class Q5UserRecommendations {

    @Context
    public GraphDatabaseService db;

    public static class UserRecommendation {
        public String recommendation;
        public long year;
        public List<List<Object>> scoreComponents;
        public long score;

        public UserRecommendation(String recommendation, long year, List<List<Object>> scoreComponents, long score) {
            this.recommendation = recommendation;
            this.year = year;
            this.scoreComponents = scoreComponents;
            this.score = score;
        }
    }

    @Procedure(name = "recommend.userRecommendations", mode = Mode.READ)
    @Description("RETURN movie recommendations for user 'Angelica Rodriguez'")
    public Stream<UserRecommendation> userRecommendations() {
        try (Transaction tx = db.beginTx()) {
            String query = "MATCH (u:User {name: 'Angelica Rodriguez'})-[r:RATED]->(m:Movie),(m)-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(rec:Movie) " +
                    "WHERE NOT EXISTS{ (u)-[:RATED]->(rec) } " +
                    "WITH rec, g.name as genre, count(*) AS count " +
                    "WITH rec, collect([genre, count]) AS scoreComponents " +
                    "RETURN rec.title AS recommendation, rec.year AS year, scoreComponents,reduce(s=0,x in scoreComponents | s+x[1]) AS score " +
                    "ORDER BY score DESC LIMIT 10";
            Result result = tx.execute(query);

            return result.stream().map(row -> new UserRecommendation((String) row.get("recommendation"), (Long) row.get("year"), (List<List<Object>>) row.get("scoreComponents"), (Long) row.get("score"))).onClose(tx::close);
        }
    }
}
