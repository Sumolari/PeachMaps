# How it works

Peach Maps includes Apple Maps files from Apple's CDN and loads a [bootstrap.json script](https://github.com/Sumolari/PeachMaps/blob/gh-pages/bootstrap.json) locally hosted to prevent 4XX errors.

MapKit offers an API to show popovers and add annotations.

Search results are currently powered by [OpenStreetMaps](https://www.openstreetmap.org/) which is queried directly from your browser via its JSONP API so you can run this project using a simple static file server and no extra dependencies.

# How it is built

This project uses [less](http://lesscss.org/) and [CoffeeScript](http://coffeescript.org/) but you don't have to install them as a compiled version of source code is included in this repo.

# What to do next

- [x] Search engine
- [ ] Directions
- [ ] Multiple annotations / custom maps
- [ ] Windowed application with Electron or similar