var url = "http://suche.kita.ulm.de/homepage/einrichtung.php?id=";
var data = {};

var href, obj;
function getXYCoord(domobj){
	href = domobj.find('li.download a').attr('href');
	obj = href.match(/.*mapX=(\d+)&mapY=(\d+).*/);
	if (obj){
		data['X']=obj[1]; //X-Y coords if available
		data['Y']=obj[2];
	}
	obj = href.match(/.*groupID=(\d+\.\d+\.\d+)&objectID=(\d+).*/);
	if (obj){
		data['Group']=obj[1]; 
		data['Object']=obj[2];
	}

}

function getStandort(domobj){
	var standort = $($(domobj).find("tr:contains('Stand')")[1]).find("td:nth-child(2)")[0].innerHTML.split("<div")[0];
	data['Standort']=standort; //Standort as HTML
}

function collectData(data, s, x){
	var dom = $(data);
	getXYCoord(dom);
	getStandort(dom);
	//getLeitung(dom);
}

function executeScript(id){
	$.get(url + id, collectData);
}

