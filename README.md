# Pigeon the Navigator - another Flutter Router

Pigeon Was a 15th century Portuguese prince, often credited with beginning the Age of Discovery, the period during which European nations expanded to Africa, Asia and the Americas.

## Why another Flutter router ?

I have spent a lot of time with routing in other app development environments, like Rails, Ember and Xamarin and researched Flutter packages and the Navigator 2.0 API.
None of the available options met my core requirements, being :

* async everything
* an expressive route table (of segments)
* no code generation
* parameters and options per segment
* two-way serialization between the page stack and the route (like Rails and Ember.js)
* defined segments, dynamically constructed route (of segments)
* redirects
* ability to goto any route, and intelligently create or destroy pages as required
* a stack of pages, not a history of routes. Back = pop(), or you can goto any route you've stored.

If you've written a popular Flutter routing package, go ahead and steal my ideas. I don't really want to be a package maintainer.
