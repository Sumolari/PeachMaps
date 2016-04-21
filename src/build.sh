#!/bin/bash
lessc --clean-css styles.less ../styles.min.css
coffee -c -m app.coffee && mv app.js.map ../ &&  mv app.js ../