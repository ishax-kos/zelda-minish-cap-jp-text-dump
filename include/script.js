function elementToggleId(id) {
    let elem = document.getElementById(id);
    if (elem.style.display == "none") {
        elem.style.display = "initial";
    }
    else {
        elem.style.display = "none";
    }
}
        
