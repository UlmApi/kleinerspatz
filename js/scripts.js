
/*
   Global map variable.
 */
var map;
var over3Layer=L.geoJson();//.addTo(map);
var under3Layer=L.geoJson();

/*
   This function translates an icon type into an actual LeafletJS icon.
   For invalid arguments, this returns an icon with the URL "img/.png"

   @param kitaStatus the status of a KITA. Valid values are 0, 1, and 2.
   @returns          a LeafletJS icon that represents the given status.
   @see L.icon
 */
function iconInstance(kitaStatus){
        var name = "";
        if(kitaStatus==0){ name = "box";}
        else if(kitaStatus==1){ name = "box-checked";}
        else if(kitaStatus==2){ name = "box-crossed";}
        return L.icon({
                iconUrl: "img/"+ name + ".png",
                shadowUrl: null,
                iconSize: [16,16],
                shadowSize: [0,0],
                iconAnchor: [8,16],
                shadowAnchor: [0,0],
                popupAnchor:[0,-16]
        });
}

/*
   Function that disables the Under3 layer and enables the Over3 layer.
   This also changes the text in the legend, but not the radial box (as this should only be called from there). 
 */
function putOver3(){
        this.over3Layer.addTo(map);
        map.removeLayer(under3Layer);
        //TODO fix this so it works again.
        //document.getElementsByClassName('over3')[0].style.fontWeight='bold';
        //document.getElementsByClassName('under3')[0].style.fontWeight='normal';
}

/*
   Function that disables the Over3 layer and enables the Under3 layer.
   This also changes the text in the legend, but not the radial box (as this should only be called from there). 
 */
function putUnder3(){
        this.under3Layer.addTo(map);
        map.removeLayer(over3Layer);
        //TODO fix this so it works again.
        //document.getElementsByClassName('under3')[0].style.fontWeight='bold';
        //document.getElementsByClassName('over3')[0].style.fontWeight='normal';
}

/*
   Main code, called after the page has loaded (see index.html).
 */
function init() {
        //create the map using LeafletJS
        map = new L.Map('map');

        L.tileLayer('http://tiles.codefor.de/static/bbs/germany/{z}/{x}/{y}.png', {
                        attribution: '<a target="_blank" href="http://ulmapi.de">UlmApi.de</a>, Stadt Ulm, Map data &copy; 2014 <a href="http://openstreetmap.org/">OpenStreetMap</a> contributors, Tiles: <a href="http://codefor.de">CfG-Map Server</a>.',
                        maxZoom: 18
                        }).addTo(map);
        //focus on Ulm, configure the appropriate zoom level
        var ulm = new L.LatLng(48.40, 9.98);
        map.setView(ulm, 13);

        //This creates a pointToLayer function for the LeafletJS layer, which is used to
        // configure a LeafletJS Marker with the appropriate icon.
        //The popups are bound using the onEachFeature fuction.
        //The display argument should be a valid parameter of the GeoJSON feature that represents a KITA.
        //In our map, this is essentially just 'over3' or 'under3', although it would
        // be possible to filter by other parameters in theory. The returned function will
        // check whether the property exists, and return a LeafletJS marker with the appropriate icon
        // for the corresponding value (no data, true or false). 
         createPointToLayer = function(display){
                return function(feature, latlng){
                        current = -1;
                        if(feature.properties[display] == null){
                                current = 0;
                        }else if(feature.properties[display] == true){
                                current = 1;
                        }else if(feature.properties[display] == false){
                                current = 2;
                        }else {
                                console.warn("Warning, property " + display+ " has an unexpected value for the following feature: " + feature);
                        }
                        icon = iconInstance(current);
                        return L.marker(latlng, {icon: icon});
                }
        }

        //This function creates the appropriate popup for each KITA based on the GeoJSON feature properties.
        //The used properties are currently:
        // name   - the name of the KITA
        // id     - the ID of the KITA (used to redirect to forms and the page at ulm.de)
        //We could also add other data we already parse (email, phone number), but we haven't done this yet, as it may lead to spam and such.
        oef = function(feature, layer) {
                var popupContent = "Kindertageseinrichtung<br><b>" + feature.properties.name + "</b><br> <br><a target='_blank' href='http://suche.kita.ulm.de/homepage/einrichtung.php?id=" + feature.properties.id + "'>Weitere Informationen</a> <br><a target='_blank' href='http://suche.kita.ulm.de/homepage/kontakt.php?Wunscheinrichtung1=" + feature.properties.id + "'>Kontaktformular</a>";
                layer.bindPopup(popupContent);
        };


        //retrieve the data as geojson
        $.getJSON("kitas.geojson", function(json) {
                console.log(json);
                data=eval(json);
                //create two layers with the appropriate filters (which in turn select the correct icons) and add the data to them.
                over3Layer  = L.geoJson(data.features, { onEachFeature: oef, pointToLayer: createPointToLayer('over3' )});
                over3Layer.addData(data);
                under3Layer = L.geoJson(data, { onEachFeature: oef, pointToLayer: createPointToLayer('under3')});
                under3Layer.addData(data);
                //also, the default config is over3; add it to the map.
                putOver3();
        });

}
