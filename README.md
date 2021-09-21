# Pelican - another Flutter Router

The Pelican is a large migratory bird https://en.wikipedia.org/wiki/Australian_pelican

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
* uses Navigator 2.0 as it was intended

If you've written a popular Flutter routing package, go ahead and steal my ideas. I don't really want to be a package maintainer.

I make no claim of the completeness or quality of this repository, but I intend to use it in production, and develop it as required by the application.
This is not the latest version, but I intend to update it from my production app.
Some intended features are not properly implemented yet.

Acknowledgements
* https://pub.dev/packages/beamer
* https://pub.dev/packages/routemaster
