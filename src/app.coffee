# Snippet from: http://stackoverflow.com/a/979995/1336641
QueryString = ( ->
  query_string = {}
  query = window.location.search.substring 1
  vars = query.split '&'
  for item in vars
    pair = item.split '='
    if typeof query_string[ pair[ 0 ] ] is 'undefined'
      query_string[ pair[ 0 ] ] = decodeURIComponent pair[ 1 ]
    else if typeof query_string[ pair[ 0 ] ] is 'string'
      arr = [ query_string[ pair[ 0 ] ], decodeURIComponent pair[ 1 ] ]
      query_string[ pair[ 0 ] ] = arr
    else
      query_string[ pair[ 0 ] ].push decodeURIComponent pair[ 1 ]
  return query_string
)()

document.addEventListener 'DOMContentLoaded', (event) ->

  ###
  Initialize MapKit and set up Map.
  ###
  mapkit.init
    apiKey: 'b2af5300a3c2ea9b5d38c782c7d2909dc88d6621',
    bootstrapUrl: './bootstrap.json'

  map = new mapkit.Map 'map'
  map.showsUserLocation = false
  map.showsUserLocationControl = true

  ###
  Set up
  ###
  router = new mapkit.Directions
    language: 'en'

  # Overlays (Polylines) currently displayed, that is, routes and directions.
  current_overlays = []
  selected_transport = mapkit.Directions.Transport.Automobile

  ###
  Object handling callout interaction.
  At the moment it just returns a popover which is displayed on top of
  annotation.
  ###
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

      directions = element.appendChild document.createElement 'div'
      directions.className = 'mk-subtitle'
      directions.innerHTML = "Directions
        <a href=\"#\" id=\"origin-link\">from here</a> |
        <a href=\"#\" id=\"destination-link\">to here</a>."

      return element

  # Currently show annotation, used to display first search result or currently
  # selected location.
  current_annotation = null
  # Timeout that will recenter map and add an annotation. Used to prevent a
  # jumpy behavior and race conditions due to asynchronous networking.
  pending_update = null

  # Route's origin and destination defined here just to set them later.
  route_origin = null
  route_destination = null

  # Search engine to use MapKit's search.
  search_engine = new mapkit.Search()

  # We need jQuery...
  $( 'document' ).ready ->

    # Currently focused location's coordinates.
    current_target = null

    # jQuery object pointing to "Share location" link.
    permalink = $ '#permalink'

    ###
    Centers map on given target and adds an annotation and a popover provided
    the proper title.

    Parameters:
      - target Object. Should have `latitude` and `longitude` attributes.
                       If `title` and `subtitles` attributes are present a
                       popover will be displayed when clicking the annotation.
    ###
    focus_target = ( target ) ->

      current_target = target

      # Hide permalink if present.
      permalink.hide()

      # Remove previous annotation.
      map.removeAnnotation current_annotation if current_annotation?

      # If neither title nor subtitle are provided just set region.
      unless target.title? and target.subtitle?
        map.setRegionAnimated new mapkit.CoordinateRegion(
          new mapkit.Coordinate( target.latitude, target.longitude ),
          new mapkit.CoordinateSpan( 0.16, 0.16 )
        )
        return

      # If title and subtitle are provided set region and add annotation.
      map.region = new mapkit.CoordinateRegion(
        new mapkit.Coordinate( target.latitude, target.longitude ),
        new mapkit.CoordinateSpan( 0.16, 0.16 )
      )

      current_annotation = new mapkit.ImageAnnotation(
        new mapkit.Coordinate( target.latitude, target.longitude ),
          callout: calloutDelegate
          title: target.title
          subtitle: target.subtitle
          url:
            1: "assets/greenDot.png",
            2: "assets/greenDot@2x.png"
      )
      map.addAnnotation current_annotation

      # Update permalink and show it.
      exportURL = "?lat=#{target.latitude}&lon=#{target.longitude}&title=\
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
        focus_target initialTarget
      , 200

    else
      initialTarget =
        latitude: 37.782851
        longitude: -122.409333

      focus_target initialTarget

      permalink.hide()

    hide_suggestions_button = $ '#hide-suggestions'
    search_suggestions = $ '#search-suggestions'
    search_suggestions_ul = $ '#search-suggestions ul'
    activity_indicator = $ '#activity_indicator'
    directions_container = $ '#directions'
    available_routes_container = $ '#available-routes'
    directions_activity_indicator = $ '#directions-activity-indicator'
    automobile_link = $ '#automobile'
    walking_link = $ '#walking'
    search_field = $ '#search'
    search_form = $ '#search-form'
    origin_span = $ '#origin'
    destination_span = $ '#destination'

    clearOverlays = ->
      for overlay in current_overlays
        map.removeOverlay overlay
      current_overlays = []

    addOverlayForRoute = ( route ) ->
      clearOverlays()
      for path in route
        coordinates = (
          new mapkit.Coordinate(
            step.latitude,
            step.longitude
          ) for step in path
        )
        path_overlay = new mapkit.PolylineOverlay coordinates
        current_overlays.push path_overlay
        map.addOverlay path_overlay

    ###
    Gets directions from origin to destination using given transport and updates
    UI.

    Parameters:
      - origin      mapkit.Coordinate. Origin of directions.
      - destination mapkit.Coordinate. Destination of directions.
      - transport   mapkit.Directions.Transport. Transport to be used.
                    Either `mapkit.Directions.Transport.Walking` or
                    `mapkit.Directions.Transport.Automobile`.
                    Defaults to `mapkit.Directions.Transport.Automobile`.
    ###
    get_directions = (
      origin,
      destination,
      transport
    ) ->

      directions_container.show()

      return unless origin? and destination?

      clearOverlays()

      directions_activity_indicator.show()
      available_routes_container.html ''

      router.route(
        origin: origin
        destination: destination
        transportType: transport,
        ( err, res ) ->
          return if err?
          routes = res.routes

          directions_activity_indicator.hide()

          route_number = 0
          for route in routes
            route_number += 1

            path_json = encodeURIComponent JSON.stringify route.path
            available_routes_container.append "<li>\
              <a href=\"#\" data-route=\"#{path_json}\">Route
              #{route_number}</a></li>"

            addOverlayForRoute route.path if route_number is 1
      )

    ###
    Hides suggestions container and close button.
    ###
    hide_suggestions = ->
      hide_suggestions_button.hide()
      search_suggestions.hide()

    ###
    Shows suggestions container and close button.
    ###
    show_suggestions = ->
      hide_suggestions_button.show()
      search_suggestions.show()

    ###
    Perform a search with given search term, updating UI properly.

    Parameters:
      - search_term String. Term to search.
    ###
    search = ( search_term ) ->
      clearTimeout pending_update if pending_update?

      hide_suggestions()
      activity_indicator.show()

      search_engine.autocomplete search_term, ( err, res ) ->
        activity_indicator.hide()

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

              show_suggestions()

              search_suggestions_ul.html ''
              for item in items

                findRegex = new RegExp "(#{search_term})", 'i'
                replace = '<strong>$1</strong>'

                highlighted_title = item.title.replace findRegex, replace

                search_suggestions_ul.append "\
                  <li><a href=\"\#\"\
                         data-latitude=\"#{item.latitude}\"
                         data-longitude=\"#{item.longitude}\"
                         data-title=\"#{item.title}\"
                         data-subtitle=\"#{item.subtitle}\">\
                           <span class=\"title\">#{highlighted_title}</span>\
                           <span class=\"subtitle\">#{item.subtitle}</span>\
                      </a></li>"

              focus_target items[0]
            , 200

    # When hide suggestions button is clicked, hide suggestions and hide button.
    hide_suggestions_button.on 'click', ( e ) ->
      e.preventDefault
      hide_suggestions()
      return false

    # When a suggestion is clicked, focus map on it.
    search_suggestions.on 'click', 'a[data-latitude]', ( e ) ->
      e.preventDefault()

      link = $ this

      target =
        latitude: parseFloat link.attr 'data-latitude'
        longitude: parseFloat link.attr 'data-longitude'
        title: link.attr 'data-title'
        subtitle: link.attr 'data-subtitle'

      focus_target target

      hide_suggestions()

      return false

    # When form is sent, search term.
    search_form.on 'submit', ( e ) ->
      e.preventDefault()
      search search_field.val()
      return false

    # When seach field changes, search term.
    search_field.on 'input', ->
      search search_field.val()

    # When clicking on "from here" button, set route origin.
    $( document ).on 'click', '#origin-link', ( e ) ->
      e.preventDefault()
      route_origin = new mapkit.Coordinate(
        current_target.latitude,
        current_target.longitude
      )
      origin_span.text current_target.title
      origin_span.addClass 'set'
      get_directions route_origin, route_destination, selected_transport
      return false

    # When clicking on "to here" button, set route origin.
    $( document ).on 'click', '#destination-link', ( e ) ->
      e.preventDefault()
      route_destination = new mapkit.Coordinate(
        current_target.latitude,
        current_target.longitude
      )
      destination_span.text current_target.title
      destination_span.addClass 'set'
      get_directions route_origin, route_destination, selected_transport
      return false

    # When clicking origin or destination labels, focus search form.
    $( '#origin, #destination' ).on 'click', ( e ) ->
      e.preventDefault()
      search_field.focus()
      return false

    # When clicking automobile link, set proper transport.
    automobile_link.on 'click', ( e ) ->
      e.preventDefault()

      selected_transport = mapkit.Directions.Transport.Automobile
      automobile_link.addClass 'selected'
      walking_link.removeClass 'selected'

      get_directions route_origin, route_destination, selected_transport

      return false

    # When clicking automobile link, set proper transport.
    walking_link.on 'click', ( e ) ->
      e.preventDefault()

      selected_transport = mapkit.Directions.Transport.Walking
      walking_link.addClass 'selected'
      automobile_link.removeClass 'selected'

      get_directions route_origin, route_destination, selected_transport

      return false

    # When clicking close directions button, hide routes and directions.
    $( '#hide-directions' ).on 'click', ( e ) ->
      e.preventDefault()
      directions_container.hide()
      return false

    # When clicking on a route link, load that route.
    available_routes_container.on 'click', 'li a', ( e ) ->
      e.preventDefault()

      route_selected = JSON.parse decodeURIComponent $( this ).attr 'data-route'

      addOverlayForRoute route_selected

      return false
