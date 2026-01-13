# Hexagonal Architecture: Planning and Thoughts

In is most simplified form, the *Hexagonal Architecture* divides and plans the codebase in the ***Business Layer*** and the ***Interface Layer***. 
The *business layer* contains the logic that controls how the code solves the specific problems being addressed, its behavior doesn't depend at all on the external environment. 
It doesn't matter if this *layer* is running on a website, a command-line interface, a videogame console, etc... All it cares is on transforming and manipulating the data
it received and provide the expected result. We could say this layer manages the ***what***. 
The *interface layer* is in charge of handling the external world, and making it suited so the *business layer* can receive data from it. It's all about contracts, any input 
must follow the *API* that the interface layer specifies. It's the gatekeeper and translator for the application. We could say it handles the ***how***.

While researching with AI, it mentioned a concept that describes very well one of the big advantages of using *hexagonal architecture*: **Technology Independence**. 
It seems that a well-designed architecture following this pattern, provides the *business layer* with independence regardless the tools being used. As long as the core logic, the
problems the business is trying to solve, doesn't change; this layer doesn't need to change.


