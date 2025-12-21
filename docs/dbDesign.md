# Some Architectural Decisions 

## On using `PostgreSQL`
After finding out that `PostgreSQL` supports natively concurrent behavior by its feature *Multi-version concurrency control*, I decided to use it.
Go and `PostgreSQL` seem to have a good synergy and be used widely in the industry, so gaining experience and learning how to integrate them is a logical decision. 

### On using `ENUM` instead of `VARCHAR` for the column `state` in the `ovens` table
It seems there are many things to keep in consideration for this, and given my current low experience using the `ENUM` data type, I'm choosing it
so I can gain a better understanding on its capabilities. 

There arguments in favor of using `VARCHAR` because it'd make the project more portable, given that `ENUM` is not standard `SQL`, but since this 
project is intended to make the most of `PostgreSQL` concurrent capabilities, portability loses importance.

Other argument against `ENUM` is that `PostgreSQL` internally stores them as integers, so queries wouldn't show the actual string value but a number. However, I don't know
how much friction or problems this behavior might generate, so I'm willing to explore and get hands-on experience on why (or why not) should I use it. 

One last argument against `ENUM` is that if need to modify or add a value, this would block operations in that column. I'm assuming the `state` for ovens is 
not going to change, and even if hypothetically the business needs to add a new *state*, this can be safely done in off-hours. 

### On using `UUID` instead of `INT` in some columns
`UUID` primary keys give the advantage of not needing to wait for the database to return us the row ID when we are trying to create a new entry. 
This provides a huge benefit when trying to create concurrent many orders in a same table, or when different servers are trying to do the same. If we used simple integer IDs, then
each concurrent operation should wait for the database to give it its assigned ID. Furthermore, using sequential IDs leads to leak information: the number of orders, the next 
order's ID, etc. Basically, in distributed systems, each node needs to create orders independently. 
