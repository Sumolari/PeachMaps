#!/bin/bash
lessc --clean-css styles.less ../styles.min.css
coffee --output ../ -c -m app.coffee