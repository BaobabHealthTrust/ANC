var timedEvent = "";
var temp = ""  

function attribute(str){
    id = str.split("*")[0]
    atr = str.split("*")[1]
    val = str.split("*")[2]
    __$(id).setAttribute(atr, val)
}
function createField(id, name, type, value){
    var node = document.createElement("input");
    node.id = id.toLowerCase();
    node.setAttribute("name", name);
    node.setAttribute("type", type);
    document.forms[0].appendChild(node);
    $(id.toLowerCase()).value = value;
}
function showApgarControl(eenum){
    apgarScore = 0;
    var apgar = {
        "APPEARANCE": 0,
        "PULSE" : 0,
        "GRIMANCE": 0,
        "ACTIVITY": 0,
        "RESPIRATION": 0
    };
    var apgarCheck = {
        "APPEARANCE": "?",
        "PULSE" : "?",
        "GRIMANCE": "?",
        "ACTIVITY": "?",
        "RESPIRATION": "?"
    };
    
    //create data handlers for  each APGAR component so they can be saved as well
    for (var key in apgar) {      
        var name = "concept[" + key.toLowerCase() + " minute " + ((eenum == 1)? "one" : "five") + "]";
        createField(key + eenum, name, "hidden", apgar[key.toUpperCase()]);
    }

    if (eenum != 1){
        alert = document.createElement("div");
    }
    
    $("clearButton").onclick = function(){
        apgarScore = 0
        if (eenum != 1){
            updateApgarAlert(apgarScore)
        }
         
        cells = document.getElementsByClassName("butt");
        for( i = 0; 0 < cells.length; i++){
            cells[i].setAttribute("selected", "false");
            cells[i].style.background = "url('/images/btn_blue.png'";
            apgar["APPEARANCE"] = 0;
            apgar["PULSE"] = 0;
            apgar["GRIMANCE"] = 0;
            apgar["ACTIVITY"] = 0;
            apgar["RESPIRATION"] = 0;
            apgarCheck["APPEARANCE"] = "?";
            apgarCheck["PULSE"] = "?";
            apgarCheck["GRIMANCE"] = "?";
            apgarCheck["ACTIVITY"] = "?";
            apgarCheck["RESPIRATION"] = "?";
            showCategory("<span style='font-size:27px;font-weight:bold;'>APGAR</span> = " + apgarCheck['APPEARANCE'] + "+" + apgarCheck['PULSE'] +"+"+ apgarCheck['GRIMANCE']
                + "+" + apgarCheck['ACTIVITY'] + "+" + apgarCheck['RESPIRATION']);
        }
    }
    $("clearButton").onclick.apply($("clearButton"));

    if (eenum != 1){
        updateApgarAlert(apgarScore);
    }
    
    scoreWindow = document.createElement("div");
    scoreWindow.setAttribute("id", "selectWindow");
	
    /*
    arr_val = ['Pale/blue', "Baby pink/</br>blue extremities", "Completely </br> pink",
      "None", "Slow -</br>Below 100 bpm", "Above </br>100 bpm",
      "Flaccid", "Some flexion </br> of Extremities", "Active Motion",
      "None", "Grimance", "Vigorous </br>cry",
      "Absent", "Slow - </br> irregular", "Good crying"];
   */
    // arr_labels = ["Color", "Heart Rate", "Muscle Tone", "Reflex Irritability", "Respiratory Effort"]

    arr = ["Appearance", "Pulse", "Grimance", "Activity", "Respiration"]
    
    arr_val = ['Pale/blue', "Baby pink/</br>blue extremities", "Completely </br> pink",
      "Absent", "Slow -</br>Below 100 bpm", "Above </br>100 bpm",
      "Flaccid", "Some flexion </br> of Extremities", "Active Motion",
      "None", "Grimance", "Vigorous </br>cry",
      "Absent", "Slow - </br> irregular", "Good crying"];
      
    arr_labels = ["Color", "Heart Rate", "Muscle Tone", "Reflex Irritability", "Respiratory Effort"]
      
    val_index = 0;
    values = [0, 1, 2];
    var labels = document.createElement("div");
    labels.id = "row1";

    placebo = document.createElement("div");
    placebo.id = "placebo";
    labels.appendChild(placebo);

    for(i = 0; i < values.length; i++){
        var lblCell = document.createElement("div");
        lblCell.setAttribute("class", "value");
        lblCell.innerHTML = (i == 2)? (i + " Points") : (i + " Point")
        labels.appendChild(lblCell);
    }
    scoreWindow.appendChild(labels);

    for (i = 0; i < arr.length; i ++){
        var row = document.createElement("div");
        row.id = "apgar_row_" + i
        row.setAttribute("class", "boardRow");

        for (j = 0; j < 4; j++){
            var control = document.createElement("div");
            control.id = "" + i + j;
            if (j != 0){

                control.setAttribute("class", "butt");
                control.setAttribute("value", j-1);
                control.setAttribute("apgar_field", arr[i]);
                // update/set selection status of the control
                if ((apgarCheck[arr[i].toUpperCase()] != "?") && ("" + i + (parseInt(apgarCheck[arr[i].toUpperCase()]) + 1) == control.id)){
                    control.setAttribute("selected", "true");
                }else{
                    control.setAttribute("selected", "false");
                }
                control.setAttribute("i", i);
                control.setAttribute("j", j);
          
                control.innerHTML = arr_val[val_index];
                val_index ++;

                control.onclick = function(){
                    var num = __$(this.id).getAttribute("value");
                    var field = __$(this.id).getAttribute("apgar_field");
                    var key = field.toUpperCase();
                    apgar[key] = num;
                    apgarCheck[key] = apgar[key];
                    //update row selections

                    if (__$(this.id).getAttribute("selected") == "false"){

                        for(k = 1; k < 4; k++){
                            var x = this.getAttribute("i");
                            __$("" + x + k).setAttribute("selected", ( this.id != "" + x + k)? "false": "true");

                            __$("" + x + k).style.background = ( this.id != "" + x + k)? "url('/images/btn_blue.png')" : "url('/images/click_btn.png')";
                            __$("" + x + k).style.Color= ( this.id != "" + x + k)? "black" : "white";
                        }
                    }
                    $(key.toLowerCase() + eenum).value = apgar[key];
                    apgarScore = parseInt(apgar['APPEARANCE']) + parseInt(apgar['PULSE'])
                    + parseInt(apgar['GRIMANCE']) + parseInt(apgar['ACTIVITY']) + parseInt(apgar['RESPIRATION']);
                    showCategory("<span style='font-size:27px;font-weight:bold;'>APGAR</span> = " + apgarCheck['APPEARANCE'] + "+" + apgarCheck['PULSE'] +"+"+ apgarCheck['GRIMANCE']
                        + "+" + apgarCheck['ACTIVITY'] + "+" + apgarCheck['RESPIRATION']);
                    if (apgarCheck["APPEARANCE"] != "?" && apgarCheck["PULSE"] != "?" && apgarCheck["GRIMANCE"] != "?" && apgarCheck["ACTIVITY"] != "?" && apgarCheck["RESPIRATION"] != "?"){
                        $('touchscreenInput'+tstCurrentPage).value = apgarScore;
                    }
                    if (eenum != 1){
                        updateApgarAlert(apgarScore);
                    }
                };

            }else{
                control.innerHTML = arr_labels[i];
                control.setAttribute("class", "leftButt");
            }
            row.appendChild(control);
        }
        scoreWindow.appendChild(row);
    }

    $('inputFrame' + tstCurrentPage).style.display = "none";
    $('page' + tstCurrentPage).style.minHeight = "650px";
    $('page' + tstCurrentPage).appendChild(scoreWindow);
    
    if (eenum != 1){
        $("page" + tstCurrentPage).appendChild(alert);
    }

}

function updateApgarAlert(apgarScore){
    if (apgarScore >= 7){
        text = "" + apgarScore.toFixed(0) + "/10 - Normal APGAR</span>";
        alert.id = "normal_apgar_alert";
    } else if (apgarScore <=3) {
        text = "" + apgarScore.toFixed(0) + "/10 - Low APGAR</span>";
        alert.id = "red_apgar_alert";
    } else {
        text = "" + apgarScore.toFixed(0) + "/10 - Fairly Low </span>";
        alert.id = "yellow_apgar_alert";
    }
    alert.innerHTML = text;
}


