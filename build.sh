#!/bin/bash
lessc --clean-css styles.less styles.min.css
coffee -c -m app.coffee