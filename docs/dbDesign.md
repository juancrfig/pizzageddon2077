# Some Architectural Decisions 

## On using `PostgreSQL`
After finding out that `PostgreSQL` supports natively concurrent behavior by its feature *Multi-version concurrency control*, I decided to use it.
Go and `PostgreSQL` seem to have a good synergy and be used widely in the industry, so gaining experience and learning how to integrate them is a logical decision. 

### On using `ENUM` instead of `VARCHAR` for the column `state` in the `ovens` table
It seems there are many things to keep in consideration for this, and given my current low experience using the `ENUM` data type, I'm choosing it
so I can gain a better understanding on its capabilities. 

There arguments in favor of using `VARCHAR` because it'd make the project more portable, given that `ENUM` is not standard `SQL`, but since this 
project is intended to make the most of `PostgreSQL` concurrent capabilities, portability loses importance.

One argument against `ENUM` is that if needed to modify or add a value, this would block operations in that column. I'm assuming the `state` for ovens is 
not going to change, and even if hypothetically the business needs to add a new *state*, this can be safely done in off-hours. 

### On using `UUID` instead of `INT` in some columns
`UUID` primary keys give the advantage of not needing to wait for the database to return us the row ID when we are trying to create a new entry. 
This provides a huge benefit when trying to create concurrent many orders in a same table, or when different servers are trying to do the same. If we used simple integer IDs, then
each concurrent operation should wait for the database to give it its assigned ID. Furthermore, using sequential IDs leads to leak information: the number of orders, the next 
order's ID, etc. Basically, in distributed systems, each node needs to create orders independently. 


### PostgreSQL is Doing Too Much

After a second analysis, I found out that PostgreSQL was doing the heavy work for me by using *triggers* and *stored procedures*. This means that my application is far from 
being **technology independent**, we are tied to PosgreSQL. This is not bad in principle, because PosgreSQL and Go present a great blend of features and capabilities to handle 
concurrent behavior efficiently. However, for the specific case of this project being built for an interview about Go, it'd be a better idea to do more stuff manually and reinvent
the wheel in some aspects, so I can get more practice, and perhaps a deeper understanding to perform well during the interview. Moreover, the fact that the business rules would 
be embedded also in the database it violates in someway the *hexagonal architecture* vision of the project. The database is going to be simply a place to store some tables with
their respective relationships. The logic of how that information behaves and interact will be managed by Go, so later in an hypothetical scenario, we could change to another 
relational database without too much problem. 
