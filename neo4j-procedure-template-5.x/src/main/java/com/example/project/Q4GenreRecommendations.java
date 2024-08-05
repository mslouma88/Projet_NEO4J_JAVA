package com.example.project;

import org.neo4j.graphdb.*;
import org.neo4j.procedure.*;

import java.util.List;
import java.util.stream.Stream;

public class Q4GenreRecommendations {

    @Context
    public GraphDatabaseService db;

    public static class GenreRecommendation {
        public String title;
        public List<String> genres;
        public long commonGenres;

        public GenreRecommendation(String title, List<String> genres, long commonGenres) {
            this.title = title;
            this.genres = genres;
            this.commonGenres = commonGenres;
        }
    }

    @Procedure(name = "recommend.genreRecommendations", mode = Mode.READ)
    @Description("RETURN movie recommendations based on genres for movie 'Inception'")
    public Stream<GenreRecommendation> genreRecommendations() {
        try (Transaction tx = db.beginTx()) {
            String query = "MATCH (m:Movie)-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(rec:Movie) " +
                    "WHERE m.title = 'Inception' " +
                    "WITH rec, collect(g.name) AS genres, count(*) AS commonGenres " +
                    "RETURN rec.title, genres, commonGenres";
            Result result = tx.execute(query);

            return result.stream().map(row -> new GenreRecommendation((String) row.get("rec.title"), (List<String>) row.get("genres"), (Long) row.get("commonGenres"))).onClose(tx::close);
        }
    }
}

