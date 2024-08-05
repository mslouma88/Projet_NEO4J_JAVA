package com.example.project;

import org.neo4j.graphdb.Node;
import org.neo4j.graphdb.Result;
import org.neo4j.graphdb.Transaction;
import org.neo4j.procedure.*;

import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * This is an example returning {@link org.neo4j.graphdb.Entity Entities} from stored procedures.
 * {@link Node Nodes} and {@link org.neo4j.graphdb.Relationship relationships} are both entities
 * and can only be accessed in their transaction. So it is important that you use the injected one
 * and not open a new one; otherwise you can access them from the outside.
 */
public class Q1MovieRecommendation {

    @Context
    public Transaction tx;



    @Procedure(name = "recommend.howManyReview", mode = Mode.READ)
    @Description("recommend.howManyReview(title)- returns number of rated per title")
    public Stream<ReviewsByMovie> howManyReview(@Name(value = "title",defaultValue = "Matrix") String title) {

        String query = "MATCH(m :Movie)<-[ :RATED]-(u:User) WHERE m.title CONTAINS '"+title+"' WITH m, count(*) AS reviews RETURN m.title AS movie, reviews ORDER BY reviews DESC ";

        Result result =tx.execute(query);
        return result.stream().map(obj->{
            return new  ReviewsByMovie((String) obj.get("movie"),(Long) obj.get("reviews"));
        }).collect(Collectors.toList()).stream();

    }

    public static class ReviewsByMovie {
        // These records contain two lists of distinct relationship types going in and out of a Node.
        public String movie;
        public Long reviews;

        public ReviewsByMovie(String movie, Long reviews) {
            this.movie = movie;
            this.reviews = reviews;
        }
    }
}
