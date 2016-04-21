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

  last_query = null
  pending_update = null

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

    search = ( search_term ) ->
      last_query?.abort()
      clearTimeout pending_update if pending_update?

      last_query = $.ajax
        url: "http://nominatim.openstreetmap.org/search",
        jsonp: "json_callback",
        dataType: "jsonp",
        data: {
          q: search_term,
          format: 'json',
          limit: 1
        },
        success: ( response ) ->

          pending_update = setTimeout ->

            return unless response[0]?

            latitude = parseFloat response[0].lat
            longitude = parseFloat response[0].lon

            display_name = response[0].display_name
            comma_position = display_name.indexOf ','
            before_first_comma = display_name.substring 0, comma_position
            after_first_comma = display_name.substring comma_position + 1

            data =
              title: before_first_comma
              subtitle: after_first_comma
              latitude: latitude
              longitude: longitude

            focusTarget data

          , 200

    search_field = $( '#search' )
    search_form = $( '#search-form' )

    search_form.on 'submit', ( e ) ->
      e.preventDefault()
      search search_field.val()
      return false

    search_field.on 'input', ->
      search search_field.val()
