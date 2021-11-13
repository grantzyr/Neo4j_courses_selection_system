// load degree
CALL apoc.load.json("file:///degrees.json") YIELD value
CREATE (
    d:Degree {
        code: value.code,
        name: value.name, 
        total_cp_min_req: value.total_cp_min_req, 
        level_100_cp_min_req: value.level_100_cp_min_req,
        level_200_cp_min_req: value.level_200_cp_min_req,
        level_300_cp_min_req: value.level_300_cp_min_req,
        level_400_cp_min_req: value.level_400_cp_min_req
    }
);

// load units
CALL apoc.load.json("file:///units.json") YIELD value
CREATE (
    u:Unit{
        code: value.code,
        title: value.title,
        level: value.level,
        cp: value.cp,
        prerequisite: value.prerequisite,
        prohibited: value.prohibited,
        or: value.or
    }
);


// set relationship
// prerequisite
MATCH (u1:Unit), (u2:Unit)
WHERE u1.code IN u2.prerequisite
MERGE (u2)-[:PREREQUISITE]->(u1);

// prohibited
MATCH (u1:Unit), (u2:Unit)
WHERE u1.code IN u2.prohibited
MERGE (u2)-[:PROHIBITED]-(u1);

// OR
MATCH (u1:Unit), (u2:Unit)
WHERE u1.code IN u2.or
MERGE (u1)-[:OR]-(u2);

// AND
MATCH (u1:Unit), (u2:Unit), (u3:Unit)
WHERE u1.code IN u3.prerequisite
AND u2.code IN u3.prerequisite
AND u1.code <> u2.code
AND NOT u1.code IN u2.or
MERGE (u1)-[:AND]-(u2);


// slide2
// has no prerequisite
// match u that u without any prerequisite Relationship
MATCH (u:Unit)
WHERE NOT (u)-[:PREREQUISITE]->(:Unit)
RETURN u;

// has a prohibition list
// match u.prohibited not empty
MATCH (u:Unit)
WHERE u.prohibited <> []
RETURN u;

// has a list of prerequisites units linked by OR operators
// match u prerequisite u1 and u2, u1 has or relationsip with u2
// u1, u2 all prerequired by u 
Match (u:Unit)-[:PREREQUISITE]->(u1:Unit)-[:OR]-(u2:Unit)
WHERE u2.code in u.prerequisite
RETURN distinct u;

// has a list of prerequisites units linked by AND and OR operators
// match u prerequisite u1 and u2 and u3, u1 has or relationsip with u2
// u2 has and relationship with u3, u1, u2, u3 all prerequired by u 
Match (u:Unit)-[:PREREQUISITE]->(u1:Unit)-[:OR]-(u2:Unit)-[:AND]-(u3:Unit)
WHERE u2.code in u.prerequisite
AND u3.code in u.prerequisite
RETURN distinct u;

// slide 3
// create student with name, sid, and completed courses
CREATE (
    s:Student{
        name: "Grant", 
        degree: "MATH", 
        sid: "88888888", 
        completed:[
            "Math100", "Math151", 
            "Math152", "Math232"
        ]
    }
);

// allowed to enrol Math240
// match all courses in u's prohibited list as u1
// if u1 not in student's completed list, 
// count(u1) = 0, then return true
// student allowed to enrol course
MATCH (u:Unit{code: "Math240"})-[:PROHIBITED]-(u1:Unit), (s: Student{sid: "88888888"})
WHERE u1.code IN s.completed
RETURN count(u1)=0 AS allowed;

// not allowed to enrol Math208W
// match all courses in u's prohibited list as u1
// if u1 in student's completed list, 
// count(u1) != 0, then count(u1) = 0 return false
// student not allowed to enrol course
MATCH (u:Unit{code: "Math208W"})-[:PROHIBITED]-(u1:Unit), (s: Student{sid: "88888888"})
WHERE u1.code IN s.completed
RETURN count(u1)=0 AS allowed;

// slide 4
// satisfy only "OR": Math251
// firstly find all u that only have OR relationship 
// or have both OR and AND relationship
// use case to find these three different situation
MATCH (u:Unit{code: "Math251"})-[:PREREQUISITE]->(u1:Unit)-[:OR]-(u2:Unit), (s:Student{sid: "88888888"})
OPTIONAL MATCH (u1)-[r:AND]-(u3:Unit)
WHERE u2.code in u.prerequisite 
AND u3.code in u.prerequisite
RETURN DISTINCT
CASE
WHEN count(u3)=0 AND (u1.code IN s.completed OR u2.code IN s.completed)
THEN TRUE
WHEN count(u3)>0 AND (u1.code IN s.completed OR u2.code IN s.completed) AND u3.code IN s.completed
THEN TRUE 
WHEN count(u3)>0 AND NOT u3.code IN s.completed 
THEN FALSE END AS Satisfied;

// satisfy both "OR" and "AND": Math308
MATCH (u:Unit{code: "Math308"})-[:PREREQUISITE]->(u1:Unit)-[:OR]-(u2:Unit), (s:Student{sid: "88888888"})
OPTIONAL MATCH (u1)-[r:AND]-(u3:Unit)
WHERE u2.code in u.prerequisite 
AND u3.code in u.prerequisite
RETURN DISTINCT
CASE
WHEN count(u3)=0 AND (u1.code IN s.completed OR u2.code IN s.completed)
THEN TRUE
WHEN count(u3)>0 AND (u1.code IN s.completed OR u2.code IN s.completed) AND u3.code IN s.completed
THEN TRUE 
WHEN count(u3)>0 AND NOT u3.code IN s.completed 
THEN FALSE END AS Satisfied;

// not satisfy both "OR" and "AND": Math419
MATCH (u:Unit{code: "Math419"})-[:PREREQUISITE]->(u1:Unit)-[:OR]-(u2:Unit), (s:Student{sid: "88888888"})
OPTIONAL MATCH (u1)-[r:AND]-(u3:Unit)
WHERE u2.code in u.prerequisite 
AND u3.code in u.prerequisite
RETURN DISTINCT
CASE
WHEN count(u3)=0 AND (u1.code IN s.completed OR u2.code IN s.completed)
THEN TRUE
WHEN count(u3)>0 AND (u1.code IN s.completed OR u2.code IN s.completed) AND u3.code IN s.completed
THEN TRUE 
WHEN count(u3)>0 AND NOT u3.code IN s.completed 
THEN FALSE END AS Satisfied;

// slide 5
// create student
CREATE (
    s:Student{
        name: "Hank", 
        sid: "66666666", 
        degree: "MATH",
        completed:[
            "Math100", "Math150",
            "Math151", "Math152", 
            "Math232", "Math240", 
            "Math251", "Math308", 
            "Math419"
        ]
    }
);

// set label
MATCH (u:Unit) WHERE u.level = 100
SET u: Level_100_courses;
MATCH (u:Unit) WHERE u.level = 200
SET u: Level_200_courses;
MATCH (u:Unit) WHERE u.level = 300
SET u: Level_300_courses;
MATCH (u:Unit) WHERE u.level = 400
SET u: Level_400_courses;

// match and sum cps for each level
// then compare with degree requirement
MATCH (s:Student{sid: "66666666"})
WITH s
MATCH (one:Level_100_courses)
WHERE one.code in s.completed
WITH s, sum(one.cp) as l100
MATCH (two:Level_200_courses)
WHERE two.code in s.completed
WITH s, l100, sum(two.cp) as l200
MATCH (three:Level_300_courses)
WHERE three.code in s.completed
WITH s, l100, l200, sum(three.cp) as l300
MATCH (four:Level_400_courses)
WHERE four.code in s.completed
WITH s, l100, l200, l300, sum(four.cp) as l400
MATCH (d:Degree{code:s.degree})
RETURN l100+l200+l300+l400>d.total_cp_min_req as Total_CP,
l100>=d.level_100_cp_min_req AS Level100_CP,
l200>=d.level_200_cp_min_req AS Level200_CP,
l300>=d.level_300_cp_min_req AS Level300_CP,
l400>=d.level_400_cp_min_req AS Level400_cp;

// slide 6
// Math152 -> Math151 -> Math150 -> Math100
MATCH p=((:Unit{code: "Math152"})-[:PREREQUISITE*]->(:Level_100_courses))
WITH length(p) as length, p
RETURN max(length), p;

// Math157 -> Math150 -> Math100
MATCH p=((:Unit{code: "Math157"})-[:PREREQUISITE*]->(:Level_100_courses))
WITH length(p) as length, p
RETURN max(length), p;

// slide 7
MATCH p=((u1:Unit)-[:PREREQUISITE*]->(u2:Unit)) 
WITH count(u2) as the_num_of_occurrences, u2
RETURN the_num_of_occurrences, u2
ORDER BY the_num_of_occurrences DESC
LIMIT 1;

// slide 8
MATCH (n)
DETACH DELETE n;
