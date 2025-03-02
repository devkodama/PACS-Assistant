/** script.js
 * 
 */


window.chrome.webview.addEventListener('message', ahkWebMessage);
function ahkWebMessage(Msg) {
    console.log(Msg.data);
    try {
        eval(Msg.data);
    }
    catch(err){
        console.log("Failed to execute");
    }
}


function ahkFormSubmit(Event) {
    let EventInfo = (Event.target.id != "" || "") ? Event.target.id : (Event.target.name != null || "") ? Event.target.name : Event.target.outerHTML;
    ahk.ahkFormSubmit(EventInfo);
}



/** Context menus - based on https://dev.to/iamafro/how-to-create-a-custom-context-menu--5d7p */

const contextmenus = new Map();
contextmenus.set("app-power", {menu: document.querySelector("#context-menu-power"), visible: false} );
contextmenus.set("app-Network", {menu: document.querySelector("#context-menu-Network"), visible: false} );
contextmenus.set("app-EI", {menu: document.querySelector("#context-menu-EI"), visible: false} );
contextmenus.set("app-PS", {menu: document.querySelector("#context-menu-PS"), visible: false} );
contextmenus.set("app-EPIC", {menu: document.querySelector("#context-menu-EPIC"), visible: false} );

const toggleMenu = (v, command) => {
    if (command === "show") {
        v.menu.style.display = "block";
        v.visible = true;
    } else {
        v.menu.style.display = "none";
        v.visible = false;
    }
};

const setPosition = (val, { top, left }) => {
    top = top - 15;
    left = left - 150;
    val.menu.style.left = `${left}px`;
    val.menu.style.top = `${top}px`;

    contextmenus.forEach( (v, k) => {
        if (v === val) {
            toggleMenu(v, "show");
        } else if (v.visible) {
            toggleMenu(v, "hide");
        }
    })
};

document.addEventListener("click", e => {
    contextmenus.forEach( (v, k) => {
        if (v.visible) {
            toggleMenu(v, "hide")
        }
    })
});

document.querySelectorAll(".context-menu-target").forEach( m => {
    m.addEventListener("contextmenu", e => {
        e.preventDefault();
        const origin = {
            left: e.clientX,
            top: e.clientY
        };
        setPosition(contextmenus.get(e.target.id), origin);
        return false;
        });
});



/* Tab functions */

// shows the page with id of pageid
// tab is the button/link that was clicked
function openTab(tabid, pageid) {
    var i, tabpages, tablinks;

    // Hide all elements with class="tabpage"
    tabpages = document.getElementsByClassName("tabpage");
    for (i = 0; i < tabpages.length; i++) {
        tabpages[i].style.display = "none";
    }

    // Remove the active class from tab icons
    tablinks = document.getElementsByClassName("tab-icon");
    for (i = 0; i < tablinks.length; i++) {
        tablinks[i].classList.remove("active");
    }

    // Show the specified page
    document.getElementById(pageid).style.display = "block";

    // Add the active class to the current tab/button
    document.getElementById(tabid).classList.add("active");
}

// Get the first tab-icon element with class="default" and click on it
document.getElementsByClassName("tab-icon default")[0].click();



/** Alert functions
 * 
 * Close button for alert boxes
 * 
 */

function closeAlert(target) {
    var div = target.parentElement;
    div.style.opacity = "0";
    setTimeout(function(){ div.style.display = "none"; div.classList.add("dismissed");}, 400);
}


/** Form element functions
 * 
 * Respond to changes in input or select elements
 * 
 */

// document.querySelector("#settingsform input").addEventListener("input", handleInput);


/* handles input or change events */
function handleCheckbox(elem) {
    // pass to ahk
    ahk.HandleFormInput(elem.id, elem.checked)
}
function handleNum(elem) {
    // pass to ahk
    ahk.HandleFormInput(elem.id, elem.value)
}
function handleText(elem) {
    // pass to ahk
    ahk.HandleFormInput(elem.id, elem.value)
}
function handleSelect(elem) {
    // pass to ahk
    ahk.HandleFormInput(elem.id, elem.value)
}