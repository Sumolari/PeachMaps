document.addEventListener 'DOMContentLoaded', (event) ->

  mapkit.init
    apiKey: 'b2af5300a3c2ea9b5d38c782c7d2909dc88d6621',
    bootstrapUrl: './bootstrap.json'

  map = new mapkit.Map 'map'
  map.showsUserLocation = false
  map.showsUserLocationControl = true

  calloutDelegate =
    calloutContentForAnnotation: ( annotation ) ->
      element = document.createElement 'div'
      element.className = 'mk-standard'

      title = element.appendChild document.createElement 'div'
      title.className = 'mk-title'
      title.textContent = annotation.title

      subtitle = element.appendChild document.createElement 'div'
      subtitle.className = 'mk-subtitle'
      subtitle.textContent = annotation.subtitle

      return element

  current_annotation = null
  pending_update = null

  search_engine = new mapkit.Search()

  $( 'document' ).ready ->

    permalink = $ '#permalink'

    focusTarget = ( target ) ->

      unless target.title? and target.subtitle?
        map.setRegionAnimated new mapkit.CoordinateRegion(
          new mapkit.Coordinate( target.latitude, target.longitude ),
          new mapkit.CoordinateSpan( 0.16, 0.16 )
        )
        return

      map.region = new mapkit.CoordinateRegion(
        new mapkit.Coordinate( target.latitude, target.longitude ),
        new mapkit.CoordinateSpan( 0.16, 0.16 )
      )

      annotation_data =
        callout: calloutDelegate
        title: target.title
        subtitle: target.subtitle
        url:
          1: "greenDot.png",
          2: "greenDot@2x.png"

      map.removeAnnotation current_annotation if current_annotation?

      current_annotation = new mapkit.ImageAnnotation(
        new mapkit.Coordinate( target.latitude, target.longitude ),
        annotation_data
      )

      map.addAnnotation current_annotation

      exportURL = "/?lat=#{target.latitude}&lon=#{target.longitude}&title=\
                   #{encodeURIComponent target.title}&subtitle=\
                   #{encodeURIComponent target.subtitle}"

      permalink.attr 'href', exportURL

      permalink.show()

    if QueryString.lat? and QueryString.lon?
      initialTarget =
        latitude: parseFloat QueryString.lat
        longitude: parseFloat QueryString.lon
      if QueryString.title?
        initialTarget.title = decodeURIComponent QueryString.title
      if QueryString.subtitle?
        initialTarget.subtitle = decodeURIComponent QueryString.subtitle

      setTimeout ->
        focusTarget initialTarget
      , 200

    else
      initialTarget =
        latitude: 37.782851
        longitude: -122.409333

      focusTarget initialTarget

      permalink.hide()

    hide_suggestions = $ '#hide-suggestions'
    search_suggestions = $ '#search-suggestions'
    search_suggestions_ul = $ '#search-suggestions ul'

    search = ( search_term ) ->
      clearTimeout pending_update if pending_update?
      search_engine.autocomplete search_term, ( err, res ) ->
        if res && res.results
          items = []
          for item in res.results
            if item.coordinate && item.displayLines
              items.push
                latitude: item.coordinate.latitude
                longitude: item.coordinate.longitude
                title: item.displayLines[0] ? ''
                subtitle: item.displayLines[1] ? ''

          if items.length > 0
            pending_update = setTimeout ->

              search_suggestions.show()
              hide_suggestions.show()

              search_suggestions_ul.html ''
              for item in items
                search_suggestions_ul.append "\
                  <li><a href=\"\#\"\
                         data-latitude=\"#{item.latitude}\"
                         data-longitude=\"#{item.longitude}\"
                         data-title=\"#{item.title}\"
                         data-subtitle=\"#{item.subtitle}\">\
                           <span class=\"title\">#{item.title}</span>\
                           <span class=\"subtitle\">#{item.subtitle}</span>\
                      </a></li>"

              focusTarget items[0]
            , 200

    search_field = $ '#search'
    search_form = $ '#search-form'

    hide_suggestions.on 'click', ( e ) ->
      e.preventDefault

      hide_suggestions.hide()
      search_suggestions.hide()

      return false

    search_suggestions.on 'click', 'a[data-latitude]', ( e ) ->
      e.preventDefault()

      link = $ this

      target =
        latitude: parseFloat link.attr 'data-latitude'
        longitude: parseFloat link.attr 'data-longitude'
        title: link.attr 'data-title'
        subtitle: link.attr 'data-subtitle'

      focusTarget target

      return false

    search_form.on 'submit', ( e ) ->
      e.preventDefault()
      search search_field.val()
      return false

    search_field.on 'input', ->
      search search_field.val()
