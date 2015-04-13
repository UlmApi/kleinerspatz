var map;
function init() {
  map = new L.Map('map');                       
       
  L.tileLayer('http://tiles.codefor.de/static/bbs/germany/{z}/{x}/{y}.png', {
     attribution: '<a target="_blank" href="http://ulmapi.de">UlmApi.de</a>, Stadt Ulm, Map data &copy; 2014 <a href="http://openstreetmap.org/">OpenStreetMap</a> contributors, Tiles: <a href="http://codefor.de">CfG-Map Server</a>.',
     maxZoom: 18
  }).addTo(map);
  //map.attributionControl.setPrefix(''); // Don't show the 'Powered by Leaflet' text.
  
  //buildCtrls().addTo(map);
  
  var ulm = new L.LatLng(48.40, 9.98); 
  map.setView(ulm, 13);


  function iconInstance(id){
    var name = "";
    if(id==0){ name = "box";}
    else if(id==1){ name = "box-checked";}
    else if(id==2){ name = "box-crossed";}
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

  //arrays for layering; one for >3, one for <3
  var over3  = [],
      under3 = [];
  
  // Get JSON for Kitas real
  $.getJSON("kita_final.json", function(json) {
    console.log(json); // this will show the info it in firebug console
    data = eval( json );
    console.log(data);
    for (var i=0; i<data.length; i++) {
      if(i==1){console.log(data[i]);}
      current_over3  = -1;
      current_under3 = -1;
      if(data[i]['over3'] == null){
        current_over3 = 0;
      }else if(data[i]['over3'] == "true"){
        current_over3 = 1;
      }else if(data[i]['over3'] == "false"){
        current_over3 = 2;
      }else {
        console.warn("Warning, bad data: " + data[i]);
      }
      if(data[i]['under3'] == null){
        current_under3 = 0;
      }else if(data[i]['under3'] == "true"){
        current_under3 = 1;
      }else if(data[i]['under3'] == "false"){
        current_under3 = 2;
      }else {
        console.warn("Warning, bad data: " + data[i]);
      }
      icon_over3  = iconInstance(current_over3);
      icon_under3 = iconInstance(current_under3);

      if(data[i]['wgs84-north'] && data[i]['wgs84-east']){ //filter non-plotable data
        var marker_over3  = L.marker([data[i]['wgs84-north'],data[i]['wgs84-east']], {'icon':icon_over3 });
        var marker_under3 = L.marker([data[i]['wgs84-north'],data[i]['wgs84-east']], {'icon':icon_under3});
        popup = "Kindertageseinrichtung<br><b>" + data[i]['name'] +  "</b><br>";
        popup += "<br><a target='_blank' href='http://suche.kita.ulm.de/homepage/einrichtung.php?id="+ data[i]['id'] +"'>Weitere Informationen</a>";
        popup += "<br><a target='_blank' href='http://suche.kita.ulm.de/homepage/kontakt.php?Wunscheinrichtung1="+ data[i]['id'] +"'>Kontaktformular</a>";
        marker_over3.bindPopup(popup);
        marker_under3.bindPopup(popup);
        over3.push(marker_over3);
        under3.push(marker_under3);
      }
    }
    //the only way to make them global seems to be to NOT declare them!
    over3Layer = L.layerGroup(over3);
    under3Layer = L.layerGroup(under3);
    over3Layer.addTo(map);
  });
}

function putOver3(){
  this.over3Layer.addTo(map);
  map.removeLayer(under3Layer);
  document.getElementsByClassName('over3')[0].style.fontWeight='bold';
  document.getElementsByClassName('under3')[0].style.fontWeight='normal';
}
function putUnder3(){
  this.under3Layer.addTo(map);
  map.removeLayer(over3Layer);
  document.getElementsByClassName('under3')[0].style.fontWeight='bold';
  document.getElementsByClassName('over3')[0].style.fontWeight='normal';
}
