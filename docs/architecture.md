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

## Thoughts and Learnings while Designing the Software System's Diagram

This is my first time designing thoughtfully a diagram for a software system. I felt tempted to start right away with the famous *components diagram*, but after doing some
research, I found that although this diagram is used, it's not usually the first step for designing a system's diagram. It seems that there's something called **C4**, which is a 
technique for modeling the architecture of software systems. *Components diagram* is the third step in this technique, now I understand why I always felt so lost and confused when
trying to draw one of these. I was skipping the previous two steps in the design/thinking process. 

### The C4 Technique

The first **C** it's the ***context diagram***. This is the highest abstraction of a system. It's intended to be easily understood for all technical and non-technical people 
involved in the development of the system.

#### The Context Diagram

The software we are trying to build is intended to solve a business problem. This problem is independent of the actual way and tools we are using to solve it. 
In *domain-driven development* this is called the **Core Domain**. 

Here we need to answer two simple questions:
1. What *things* are the main actors in the business film?
2. What are the most basic rules that dictate how these *things* behave and interact together? 

In this project, I have three main entities: **Pizzas**, **Ovens**, and **Orders**.
These are some rules about these entities:
- Pizzas are pre-made, so they are self-contained in terms of stock. No need to track individual ingredients stock for different pizzas. 
- An oven cannot bake two pizzas at once. 
- Ovens cannot bake pizzas with stock less or equal than zero.
- An order has a duration.
- Ovens randomly breakdown.
- An order can only have one pizza. 

#### The Container Diagram

This is about taking the black-box we defined in the previous diagram, and identify the so-called **runtime units**, which are basically the independent services that the 
black-box uses. In this case we have the main **Pizzeria Service**, the **Trauma Service**, and the **Relational Database**.

#### The Components Diagram

