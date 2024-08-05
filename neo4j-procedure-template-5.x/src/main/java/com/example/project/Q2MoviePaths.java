package com.example.project;


import org.neo4j.graphdb.*;
import org.neo4j.procedure.*;

import java.util.stream.Stream;

public class Q2MoviePaths {

    @Context
    public GraphDatabaseService db;

    public static class MoviePath {
        public Path path;

        public MoviePath(Path path) {
            this.path = path;
        }
    }

    @Procedure(name = "recommend.moviePaths", mode = Mode.READ)
    @Description("RETURN paths connected to movie 'Net, The'")
    public Stream<MoviePath> moviePaths() {
        try (Transaction tx = db.beginTx()) {
            String query = "MATCH p=(m:Movie {title: 'Net, The'})-[:ACTED_IN|IN_GENRE|DIRECTED*2]-() " +
                    "RETURN p LIMIT 25";
            Result result = tx.execute(query);

            return result.stream().map(row -> new MoviePath((Path) row.get("p"))).onClose(tx::close);
        }
    }
}
