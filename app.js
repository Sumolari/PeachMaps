// Generated by CoffeeScript 1.10.0
(function() {
  document.addEventListener('DOMContentLoaded', function(event) {
    var calloutDelegate, current_annotation, last_query, map, pending_update;
    mapkit.init({
      apiKey: 'b2af5300a3c2ea9b5d38c782c7d2909dc88d6621',
      bootstrapUrl: './bootstrap.json'
    });
    map = new mapkit.Map('map');
    map.showsUserLocation = false;
    map.showsUserLocationControl = true;
    calloutDelegate = {
      calloutContentForAnnotation: function(annotation) {
        var element, subtitle, title;
        element = document.createElement('div');
        element.className = 'mk-standard';
        title = element.appendChild(document.createElement('div'));
        title.className = 'mk-title';
        title.textContent = annotation.title;
        subtitle = element.appendChild(document.createElement('div'));
        subtitle.className = 'mk-subtitle';
        subtitle.textContent = annotation.subtitle;
        return element;
      }
    };
    current_annotation = null;
    last_query = null;
    pending_update = null;
    return $('document').ready(function() {
      var focusTarget, initialTarget, permalink;
      permalink = $('#permalink');
      focusTarget = function(target) {
        var annotation_data, exportURL;
        if (!((target.title != null) && (target.subtitle != null))) {
          map.setRegionAnimated(new mapkit.CoordinateRegion(new mapkit.Coordinate(target.latitude, target.longitude), new mapkit.CoordinateSpan(0.16, 0.16)));
          return;
        }
        map.region = new mapkit.CoordinateRegion(new mapkit.Coordinate(target.latitude, target.longitude), new mapkit.CoordinateSpan(0.16, 0.16));
        annotation_data = {
          callout: calloutDelegate,
          title: target.title,
          subtitle: target.subtitle,
          url: {
            1: "greenDot.png",
            2: "greenDot@2x.png"
          }
        };
        if (current_annotation != null) {
          map.removeAnnotation(current_annotation);
        }
        current_annotation = new mapkit.ImageAnnotation(new mapkit.Coordinate(target.latitude, target.longitude), annotation_data);
        map.addAnnotation(current_annotation);
        exportURL = "/?lat=" + target.latitude + "&lon=" + target.longitude + "&title=" + (encodeURIComponent(target.title)) + "&subtitle=" + (encodeURIComponent(target.subtitle));
        permalink.attr('href', exportURL);
        return permalink.show();
      };
      if ((QueryString.lat != null) && (QueryString.lon != null)) {
        initialTarget = {
          latitude: parseFloat(QueryString.lat),
          longitude: parseFloat(QueryString.lon)
        };
        if (QueryString.title != null) {
          initialTarget.title = decodeURIComponent(QueryString.title);
        }
        if (QueryString.subtitle != null) {
          initialTarget.subtitle = decodeURIComponent(QueryString.subtitle);
        }
        setTimeout(function() {
          return focusTarget(initialTarget);
        }, 200);
      } else {
        initialTarget = {
          latitude: 37.782851,
          longitude: -122.409333
        };
        focusTarget(initialTarget);
        permalink.hide();
      }
      return $('#search').on('input', function() {
        var search_term;
        search_term = $(this).val();
        if (last_query != null) {
          last_query.abort();
        }
        if (pending_update != null) {
          clearTimeout(pending_update);
        }
        return last_query = $.ajax({
          url: "http://nominatim.openstreetmap.org/search",
          jsonp: "json_callback",
          dataType: "jsonp",
          data: {
            q: search_term,
            format: 'json',
            limit: 1
          },
          success: function(response) {
            return pending_update = setTimeout(function() {
              var after_first_comma, before_first_comma, comma_position, data, display_name, latitude, longitude;
              if (response[0] == null) {
                return;
              }
              latitude = parseFloat(response[0].lat);
              longitude = parseFloat(response[0].lon);
              display_name = response[0].display_name;
              comma_position = display_name.indexOf(',');
              before_first_comma = display_name.substring(0, comma_position);
              after_first_comma = display_name.substring(comma_position + 1);
              data = {
                title: before_first_comma,
                subtitle: after_first_comma,
                latitude: latitude,
                longitude: longitude
              };
              return focusTarget(data);
            }, 200);
          }
        });
      });
    });
  });

}).call(this);

//# sourceMappingURL=app.js.map